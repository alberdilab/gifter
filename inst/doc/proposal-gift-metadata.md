# Curation proposal: multi-facet GIFT metadata

Status: **proposal, not implemented.**
Prepared 2026-08-18 against database version 2026.10.1 (schema 4).

Scope: decide how GIFTs should be classified beyond the single `category`
column, so that the database supports ecological and physiological questions
without extending gifter's modelling scope.

All open questions were resolved on 2026-08-18. The answers are recorded in
section 8 and worked into the design below: `category` is retired at schema 5
and reproduced losslessly from three facets (§8.1); `resource_origin` is
multi-valued (§8.2); and gifter targets bacteria and archaea only, which
removes the need for a taxon qualifier on `biomass_essential` (§8.3).

---

## 1. Recommendation in one page

Do not add more columns to `gift`. Add **two layers**:

```text
CURATED     gift_facet / anchor_facet     multi-valued, controlled vocabulary
DERIVED     gift_profile view             computed from anchors + gift_graph
```

The curated layer carries only what a curator must assert and nothing else can
supply. The derived layer computes the rest, at build time, from data the
database already holds. Most of the ecological signal that `category` currently
hides is in the second group — it needs a view, not a curation campaign.

Four decisions:

1. **`category` is one column doing three jobs** — substrate class, substrate
   tier and process. `sugar_degradation` and `polysaccharide_degradation`
   differ only in tier; `sugar_degradation` and `sugar_transport` only in
   process. None of the three axes can be queried on its own. Retire the column
   and recover every current value from the three facets that replace it
   (§8.1).
2. **Facets are multi-valued and namespaced**, following the pattern already
   used for markers and pathway cross-references. A new axis then costs a
   vocabulary row, not a schema migration.
3. **Substrate provenance belongs to the anchor, not the GIFT.** Arabinoxylan
   is plant-derived wherever it appears; asserting that once per anchor keeps
   28 GIFTs from disagreeing about it.
4. **Do not curate what the graph can derive**, and do not curate what is a
   property of a genome collection rather than of a trait (§6).

---

## 2. What `category` cannot express today

| Question | Answer today |
|---|---|
| Which GIFTs act on host-derived glycans? | not recorded |
| Which release their product outside the cell? | derivable, not exposed |
| Which are entry points into the catabolic network? | derivable, not exposed |
| Which indicate auxotrophy when absent? | not recorded |
| Which routes need oxygen? | not recorded |
| Group GIFTs by substrate class *and* by process | impossible; one column |

`neuac_degradation` and `xylose_degradation_isomerase` share a category. One is
a host mucin-derived sialic acid consumed by gut symbionts and pathogens; the
other is a plant fibre pentose. For an ecological comparison that is the
distinction that matters, and the schema currently discards it.

---

## 3. Curated layer

### 3.1 Schema

```sql
CREATE TABLE gift_facet (
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  facet TEXT NOT NULL,
  value TEXT NOT NULL,
  notes TEXT,
  PRIMARY KEY (gift_pk, facet, value)
);

CREATE TABLE anchor_facet (
  anchor_pk INTEGER NOT NULL REFERENCES anchor(anchor_pk),
  facet TEXT NOT NULL,
  value TEXT NOT NULL,
  notes TEXT,
  PRIMARY KEY (anchor_pk, facet, value)
);

-- Registered vocabulary. Open to new facets, closed within a facet: the
-- build rejects a (facet, value) pair that is not defined here, which is what
-- keeps a multi-valued column from degenerating into free text.
CREATE TABLE facet_term (
  facet TEXT NOT NULL,
  value TEXT NOT NULL,
  applies_to TEXT NOT NULL CHECK (applies_to IN ('gift', 'anchor')),
  definition TEXT NOT NULL,
  PRIMARY KEY (facet, value)
);
```

Sources: `gift_facets.tsv`, `anchor_facets.tsv`, `facet_terms.tsv`.

### 3.2 Anchor facets

**`resource_origin`** — where the molecule comes from, in a host-associated or
environmental setting. The highest-value addition in this proposal, and the one
nothing else can supply. **Multi-valued** (§8.2): glucose is both `diet_plant`
and `host_glycan`, and forcing a single value would make one of those a false
negative.

```text
diet_plant | diet_animal | host_glycan | host_secretion
microbial_product | environmental | endogenous
```

`endogenous` marks molecules arising intracellularly, such as PRPP or IMP. It
is not exclusive of the others — an anchor can be both made and taken up. The
build warns on an anchor with no `resource_origin` at all, since the facet is
meant to be total; it does not constrain how many values an anchor carries.

**`biomass_essential`** — whether the molecule is a required cellular building
block (`yes` / `no`). Twenty of the current anchors settle in one pass, and it
is what licenses the auxotrophy inference in §4. No taxon qualifier: gifter
targets bacteria and archaea only (§8.3).

**`molecular_tier`** — `polymer`, `oligosaccharide`, `monomer` or
`small_molecule`. Objective, and needed to retire `category` without loss: it
is the axis that separates `xylan_degradation` from
`xylose_degradation_isomerase`. Deriving it from anchor names or ChEBI would be
guesswork, so it is curated once per anchor rather than inferred.

### 3.3 GIFT facets

**`substrate_class`** — the chemistry domain the capability operates in.

```text
carbohydrate | amino_acid | nucleotide | lipid | cofactor
sulfur | nitrogen | aromatic | one_carbon
```

Required and **single-valued**, the one facet with that constraint: it is the
primary display grouping that replaces `category`, and a GIFT spanning two
chemistry domains is a sign the boundaries need review, not a labelling
problem.

**`physiological_role`** — what the capability does for the cell.

```text
nutrient_acquisition | precursor_supply | energy_conservation
redox_balancing | detoxification | osmotic_or_stress_response
```

Independent of `mode`: `mode` states chemical direction, this states purpose.
Both `xylose_uptake_abc` (transport) and `xylan_degradation` (catabolic) are
`nutrient_acquisition`.

**`host_interaction`** — the microbiome-facing axis, curated only where a
literature claim exists.

```text
scfa_production | vitamin_provisioning | bile_acid_transformation
mucin_degradation | xenobiotic_metabolism | immunomodulatory_product
```

Sparse by design. Absence means "not asserted", never "no".

### 3.4 Route facet, not a GIFT facet

`oxygen_requirement` (`aerobic` / `anaerobic` / `independent`) belongs on
`gift_route`, because alternative routes to the same anchors genuinely differ —
a glycyl radical route is oxygen-sensitive where its counterpart is not.
Recording it on the GIFT would flatten exactly the distinction the OR-over-
routes model exists to preserve. It also lets `evaluate_gifts()` report that a
genome's only complete route is an anaerobic one, which is an ecological
statement about the organism.

---

## 4. Derived layer

A `gift_profile` view, computed from anchors, compartments and `gift_graph`.
None of this is curated; all of it is currently invisible.

| Field | Derivation | Ecological meaning |
|---|---|---|
| `resource_strategy` | input/output compartments | `public_good` (extracellular in and out), `uptake`, `private` (cytoplasmic), `unresolved` |
| `network_position` | in/out degree in `gift_graph` | `entry`, `intermediate`, `terminal`, `isolated` |
| `cross_feeding_output` | output anchor is extracellular and is another GIFT's input | the trait releases a resource others consume |
| `auxotrophy_indicator` | `mode = anabolic` and output anchor is `biomass_essential` | absence of any complete route predicts a nutritional dependency |
| `substrate_tier` | `molecular_tier` of the input anchors | polymer, oligo, mono — with `substrate_class` and `mode`, reproduces `category` |

The §5 query shows this already resolves for the curated sugar GIFTs.
`xylan_degradation` is extracellular in and out — a public good, whose product
another organism's `xylose_uptake_abc` can take. That is the
degrader-versus-forager distinction the architecture guide names as motivation
for the compartment field, and it needs no new curation to expose.

`auxotrophy_indicator` is the largest new capability here: it turns a set of
per-genome trait calls into a dependency network across genomes, which is the
usual reason to want ecological metadata in the first place.

---

## 5. What this looks like in practice

```sql
-- Host-glycan foragers that keep the product to themselves
SELECT g.gift_id FROM gift g
JOIN gift_anchor ga ON ga.gift_pk = g.gift_pk AND ga.role = 'input'
JOIN anchor_facet af ON af.anchor_pk = ga.anchor_pk
JOIN gift_profile p ON p.gift_id = g.gift_id
WHERE af.facet = 'resource_origin' AND af.value = 'host_glycan'
  AND p.resource_strategy = 'private';
```

API surface, additive only:

```r
list_gifts(facet = "physiological_role", value = "nutrient_acquisition")
get_gift_facets("neuac_degradation")
gift_profile()                       # the derived view
evaluate_gifts(..., profile = TRUE)  # facets joined onto the calls
```

The HTML report already groups by `category` through one `<select>`; the same
control generalises to any registered facet, which is the whole user-visible
payoff for the report.

---

## 6. Deliberately excluded

- **Prevalence, core/accessory status, discriminative power.** These are
  properties of a genome collection, not of a trait. They belong to the
  evaluation and reporting layer, computed per dataset. Curating "this GIFT is
  common" would bake one reference set into the ontology.
- **Environment or habitat tags** (`gut`, `soil`, `rumen`). gifter states
  what a genome encodes, not where it lives. `resource_origin` carries the
  usable part of this without the scope violation, because provenance is a
  property of the molecule.
- **ATP yield, energy conservation stoichiometry.** Requires the reaction
  stoichiometry the architecture guide explicitly excludes from runtime.
  `physiological_role = energy_conservation` is a qualitative claim and stays
  qualitative.
- **Taxonomic distribution.** Same objection as prevalence.

---

## 7. Cost and sequencing

28 GIFTs and 42 anchors. Retro-curation is small.

1. Schema, vocabulary table and build validation; `facet_terms.tsv` defined.
2. `anchor_facets.tsv`: `resource_origin` and `biomass_essential` for all 42
   anchors. No GIFT edits.
3. `gift_profile` view and `gift_profile()`. Derived only — measurable payoff
   before any GIFT-level curation.
4. `gift_facets.tsv`: `physiological_role` for all 28, `host_interaction`
   where evidenced.
5. `oxygen_requirement` on `gift_route`.
6. Report grouping generalised over registered facets; `category` dropped at
   schema 5, after a build-time check that `substrate_class` × `substrate_tier`
   × `mode` reproduces all five current values (§8.1).

Steps 2 and 3 are independently useful and carry no risk to existing calls.
Facets do not enter the completeness logic at any step: they classify a call,
they never change it.

---

## 8. Resolved questions

### 8.1 `category` is dropped at schema 5

Keeping it as a stored derived label would denormalise a value that can drift
from the facets it summarises, and 0.1.0 is unreleased on this branch, so there
is no downstream code to protect — the compatibility argument for keeping it is
never weaker than it is now.

Nothing is lost, because the triple reproduces every current value:

| `category` | `substrate_class` | `substrate_tier` | `mode` |
|---|---|---|---|
| `amino_acid_biosynthesis` | amino_acid | small_molecule | anabolic |
| `nucleotide_biosynthesis` | nucleotide | small_molecule | anabolic |
| `polysaccharide_degradation` | carbohydrate | polymer | catabolic |
| `sugar_degradation` | carbohydrate | monomer | catabolic |
| `sugar_transport` | carbohydrate | monomer | transport |

The two pairs that collide on any single axis — the first two rows on tier and
mode, the last three on class — are separated by the remaining ones. That table
is worth asserting as a build-time check while both representations exist, then
deleting with the column.

This is also the evidence for the §2 claim: `category` was doing exactly three
jobs, and the three facets are not a finer subdivision of it but the axes it
had collapsed.

### 8.2 `resource_origin` is multi-valued

Adopted as in §3.2. Two consequences worth stating:

- Queries that filter on one origin return **supersets**, not partitions. A
  count of "host-glycan GIFTs" and a count of "plant-fibre GIFTs" may overlap
  and must not be presented as shares of a whole. The report should render the
  facet as tags, never as a pie chart.
- The derived `resource_strategy` in §4 stays single-valued, because it comes
  from compartments rather than provenance. Multi-valued origin does not
  propagate into it.

### 8.3 No taxon qualifier on `biomass_essential`

gifter targets **bacteria and archaea only**. Within that scope the amino
acid, nucleotide and cofactor building blocks are universal, so a plain
`yes`/`no` carries no hidden taxonomic assumption.

That scope statement is currently recorded nowhere — not in `AGENTS.md`,
`inst/doc/architecture.md`, `README.md` or `DESCRIPTION`. It is load-bearing
well beyond this proposal: it is what licenses universal essentiality claims,
constrains which marker namespaces are meaningful, and tells a user whether a
eukaryotic MAG is a supported input. It should be added to the scope section of
the architecture guide independently of whether this proposal proceeds.
