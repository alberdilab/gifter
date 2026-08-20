# gifter package changelog

Code, public API, evaluation logic, and report changes. Newest first.
Timestamps are UTC.

**Biological database changes are not recorded here.** They live in the
database itself, as `inst/extdata/database-source/database_changes.tsv` and
`change_gifts.tsv`, linked to the GIFTs they affect. Read them with
`database_changelog()`, or open the Changelog view of the HTML atlas. That
separation is deliberate: a biological decision is versioned with the content
it describes and travels with the compiled database, while a code decision is
versioned with the package.

---

## Package 0.1.0 (in development)

### 2026-08-20T11:35Z — Named reference universes make recurring analyses reusable

**Change.** Schema 7 and biological database 2026.20.4 add a normalized registry
of 19 named reference universes, their metadata filters, boundedness claims,
interpretation limits and scope-specific metric recommendations. The new
`list_gift_universes()` accessor discovers them, and
`gift_universe(preset = ...)` resolves a preset against the current database
release. Documentation now demonstrates the carbohydrate-degradation and
biomass-essential-anabolism presets. **No GIFT definition, evaluation logic or
Boolean call changes.**

**Why.** Questions such as carbohydrate degradation, nitrogen acquisition,
fermentation-product formation and vitamin biosynthesis were already expressible
with `gift_universe()`, but every analysis had to restate their biological
scope. A versioned registry makes those scopes easy to find and consistent
between genome and community analyses without hard-coding GIFT identifiers.

**Effect.** Preset filters are ORed within a metadata key and ANDed across keys;
membership therefore follows `gift_type`, `mode`, curated facets and the derived
`gift_profile` as the catalogue changes. Open presets cannot be promoted to
bounded at runtime. Only biomass-essential anabolism and its amino-acid,
nucleotide and cofactor subsets ship as bounded. Cycle closure and community
handoffs remain graph-derived rather than being reduced to set membership.

### 2026-08-20T09:35Z — Documentation and Atlas share one navigation model

**Change.** The package website and GIFT Atlas now expose the same primary
destinations: API reference, ordered tutorial articles, and the Atlas. The
Atlas keeps its Overview, GIFT explorer, Changelog, SQL schema, and Tables
controls as a separate local navigation row. The article index and menu now
declare the intended tutorial sequence explicitly: 1, 2, then 3. **No
biological, schema, database, evaluation, or public API change.**

**Why.** Atlas-only controls previously occupied the position used for global
documentation navigation, leaving no direct route back to the API reference or
vignettes. Pkgdown also inferred article order from filenames, which displayed
tutorial 3 before tutorials 1 and 2.

**Effect.** Users can move between the reference, articles, and Atlas from the
same place on either surface, while Atlas views remain close at hand. Both the
article landing page and its menu present the tutorials in reading order.

### 2026-08-20T09:03Z — Website adopts the gifter gear logo

**Change.** The supplied three-gear SVG is now the package website and database
atlas logo, with its oversized source artboard cropped at the SVG `viewBox` so
that the artwork scales cleanly in the navigation bars and pkgdown page headers.
The top-left wordmark now renders `gift` in forest green and `er` in the theme's
muted grey. **No biological, schema, database, evaluation, or public API
change.**

**Effect.** The documentation site and self-contained atlas use the new logo at
every viewport size and keep the full `gifter` name as one accessible home or
overview link while presenting the requested two-color wordmark.

### 2026-08-20T08:35Z — Documentation and atlas share one visual environment

**Change.** The pkgdown website now uses the database atlas's palette,
typography, brand mark, header proportions, segmented navigation, search
control, content surfaces, and responsive spacing across the home, tutorial,
and API reference pages. Pkgdown's generated structure, navigation, search,
table of contents, and reference content are unchanged. **No biological,
schema, database, evaluation, or public API change.**

**Why.** The documentation and reference atlas are adjacent parts of the same
published site, but the former used the default Bootstrap presentation while
the latter had its own complete visual system. Moving the documentation into
that system makes transitions between explanation and database exploration
feel continuous and gives future pages a common layout environment.

**Effect.** Documentation pages and the atlas now share a warm paper ground,
forest and mint controls, serif display headings, compact rounded navigation,
and the same responsive visual rhythm. The atlas remains a self-contained
offline-capable report, and the documentation remains standard generated
pkgdown output.

### 2026-08-20T08:02Z — Database atlas published with the package website

**Change.** The package now has a pkgdown website deployed to GitHub Pages by
GitHub Actions. The workflow installs the package, builds its reference and
vignette documentation, and generates `atlas/index.html` from the SQLite
database in that same installation. The atlas is checked on pull requests and
deployed from `main`. **No schema, database content, or evaluation change.**

**Why.** The 8.7 MB self-contained atlas was installed beside the 1.6 MB SQLite
database from which it can be reproduced. That duplicated database content,
inflated every installation, and gave a generated report the appearance of a
second packaged source artifact.

**Effect.** The current atlas is browsable at
`https://alberdilab.github.io/gifter/atlas/`. Users can still create an offline
or shareable report with `write_gifter_database_html()`, but
`inst/extdata/gifter-database.html` is no longer shipped. The curated TSV
sources remain authoritative and the SQLite database remains the compiled
runtime artifact.

### 2026-08-20T06:16Z — Package renamed from giftr to gifter

**Change.** The R package is now named `gifter`, avoiding the
case-insensitive CRAN name collision with the archived package `GIFTr`.
Package loading, qualified calls, help aliases, S3 classes, internal
package-prefixed identifiers, tests, vignettes, development files, and the
packaged database/schema/report filenames now use `gifter`. The
package-prefixed database release column is `gifter_db_version`; its value and
the independent biological database and schema versions are unchanged.

**Compatibility.** The exported functions `giftr_community()`,
`giftr_db_connect()`, `giftr_db_disconnect()`, `giftr_db_version()`,
`validate_giftr_sources()`, `build_giftr_database()`, and
`write_giftr_database_html()` remain as documented aliases of their `gifter_*`
replacements. Returned objects carry their former `giftr_*` S3 class as a
secondary class, and version metadata retains a deprecated
`giftr_db_version` field mirroring `gifter_db_version`.

**Effect.** New code installs and loads `gifter` and should use the canonical
`gifter_*` names. GIFT definitions, routes, marker evidence, evaluation logic,
database release, and schema version do not change. The repository now lives at
`https://github.com/alberdilab/gifter` following its separate external rename.

### 2026-08-19T06:10Z — Three tutorial vignettes covering a complete analysis

**Change.** A new `vignettes/` directory with three executed `.Rmd` tutorials,
`knitr` and `rmarkdown` added to `Suggests` with `VignetteBuilder: knitr`, a
*Tutorials* section in `README.md`, and a row in the AGENTS work table. **No
code, schema or database change.**

**Why.** The package had reference documentation and design records but no path
in. A newcomer holding an annotation table could not find out, from anything
shipped, how to get from that table to a call, or what a call was allowed to
mean once they had one.

**Effect.** `evaluating-a-genome` covers the input format, which markers gifter
could use, reading complete and incomplete calls, and tracing a call to genes.
`quantitative-traits` covers reference universes and why a count without one is
not a result. `community-analysis` covers provider counts, presence versus
abundance, and the handoff network.

They are `.Rmd` rather than static markdown so that every chunk is executed at
`R CMD build` and re-executed at `R CMD check`. A tutorial whose output is
pasted in by hand starts drifting from the package the day it is written; these
cannot, because the check fails first.

**The vignettes teach the refusals, not only the API.** Each one is built around
a case where gifter declines to answer, because those are the places a newcomer
will otherwise misread the output: the genome that completes
`chemotaxis_signal_transduction` and not `aspartate_chemoreception`, on a
generic chemoreceptor accession that cannot license a ligand-specific claim; the
absent `supported_fraction` over an open catalogue; the 55%-complete MAG whose
fraction rises to 1.0 while its richness does not move; and the two genomes that
each encode xylose uptake and xylose catabolism and still produce no edge
between them, because `XYLOSE_IN` is cytoplasmic.

The illustrative genomes are labelled as fixtures built from the curated
database, not presented as annotation output from named organisms, and the AGENTS
work table now records that as the standard for tutorial content. The
arabinoxylan community is the same curated chain the community tests use.

`R CMD check --no-manual` on the built tarball, vignettes included: one NOTE,
the pre-existing installed size. `Config/build/clean-inst-doc: FALSE` keeps the
design proposals in `inst/doc` alongside the built vignettes.

### 2026-08-19T05:25Z — The quantitative layer is documented and its invariants are rules

**Change.** Documentation only. `inst/doc/architecture.md` gains a
**Quantitative traits** section and three quick-index entries; `AGENTS.md`
gains invariants 20-23, a row in *Work in the correct files* and a testing
bullet; `README.md` gains a *Summarise genomes and communities* section;
`inst/doc/proposal-quantitative-traits.md` becomes accepted and implemented and
carries the implementation record. **No code, schema or database change.**
This is phase 5 of that proposal.

**Why.** The layer's four constraints are not conventions an author could
reasonably choose otherwise about: a universe built in R rather than from
curated metadata, a fraction of an open catalogue, a quality policy that
promotes a call, or an edge that hands a cytoplasmic molecule between organisms
are each a defect rather than a style. Constraints of that kind belong in the
invariant list, where they are checked before a change ships, and not only in
the roxygen of the function that happens to enforce them today.

**Effect.** Invariant 20 requires a declared reference universe built from
curated metadata and forbids a fraction of the catalogue unless the universe was
declared bounded. Invariant 21 keeps presence, abundance and context apart and
fixes genome quality as informing absence only, per genome. Invariant 22 bounds
interaction edges to existing compatibility semantics, requires them to inherit
`edge_quality`, and requires an `extracellular` anchor to cross organisms.
Invariant 23 requires traceability and prefers interpretable components to
composite indices.

The implementation record states both departures from the plan. The first
changes results: a cross-genome edge needs an extracellular anchor, which the
plan did not anticipate and the arabinoxylan fixture found. The second is that
the externally drafted source proposal was **not** copied into `inst/doc/`, as
the plan had said it would be; §2, §3 and §8 of the superseding document already
record what it got right, every duplication and gap with evidence, and every
refusal with a reason, and 1400 further lines saying the same thing less
accurately would make the design record harder to read rather than more
complete.

`R CMD check --no-manual` on the built tarball: one NOTE, the pre-existing
installed size of the compiled database and HTML atlas. Full suite green at
3566.

### 2026-08-19T05:05Z — Assessability: when a negative call may enter a denominator

**Change.** A new internal layer in `R/assessability.R`, and `quality`,
`policy` and `threshold` arguments on `genome_traits()` and
`gifter_community()`. Two new metrics, `assessable_fraction` and
`provider_fraction`. **No schema, database content or evaluation change.**
This is phase 4 of `inst/doc/proposal-quantitative-traits.md`, and the gap that
made the externally drafted proposal unimplementable as written.

**Why.** `evaluate_gifts()` answers one question — do the observed markers
support a complete curated implementation — and answers it identically for a
closed isolate genome and a 60%-complete MAG, because the markers are all it
sees. That is right for a call and wrong for a denominator: a genome that was
never fully observed has not been shown to lack anything. Every proportion in
this layer was resting on that conflation.

**Effect.** A third state sits on top of the Boolean call under an explicitly
named policy. `"none"` is the default and declares nothing indeterminate, so
existing behaviour is unchanged and `assessable_fraction` states the assumption
in the output rather than leaving it implied. `"completeness"` requires a
genome completeness estimate and an explicit threshold, and treats every
negative call on a genome below that threshold as indeterminate, removing it
from every denominator while leaving every positive call exactly as it was.

Two constraints bind every policy that will ever be added here, and both are
tested. No policy may promote an unsupported GIFT to supported: quality informs
the reading of absence and nothing else. And indeterminacy is resolved per
genome, so a fragmented member's silence is withheld from a provider
denominator while a complete member's is not — which is what `provider_fraction`
now divides by.

Three refusals. The `"completeness"` policy has **no default threshold**,
because how complete a genome must be before its silence is informative is the
analyst's declared choice and a package default would be read as a
recommendation. The policy is deliberately blunt — it does not try to guess
which capability a fragmented assembly lost — because gifter has no validated
model of gene loss and a finer rule would imply a precision it cannot support;
the graduated `"near_miss"` policy stays recorded as a candidate rather than
shipped. And a proportion computed over a universe that has quietly collapsed
now warns: at 30% completeness a supported fraction of 1.0 over one assessable
GIFT is arithmetically fine and biologically empty, so the reader is pointed at
`assessable_fraction` before they quote it.

28 new tests in `test-assessability.R`; full suite green at 3566.

### 2026-08-19T04:45Z — Community resource-handoff topology, bounded by the compartment model

**Change.** One new exported function, `community_network()`, in the new
`R/community-network.R`. **No schema, database content or evaluation change.**
This is phase 3 of `inst/doc/proposal-quantitative-traits.md`.

**Why.** `gift_graph` already decides when one GIFT's declared output anchor
reaches another's declared input. Projecting that decision onto a pair of
genomes is the whole of community topology, and inventing a second
compatibility rule for it would put a biological definition in two places.

**Effect.** A directed edge means one genome supports a GIFT whose output anchor
another genome's supported GIFT consumes. Edges carry the `from_gift`,
`to_gift`, `shared_anchor` and the `edge_quality` of the GIFT edge beneath them,
so a handoff resting on an unlicensed compartment reads as
`compartment_inexact` rather than as an ordinary edge. `chain_coverage`
classifies every curated composition link as completed `within_genome`,
completed only `community_distributed`, `not_transferable`, or
`not_represented`, retaining the genomes behind each. `cycle_coverage` asks the
same question of the elementary cycles of the anchor graph.

**One rule was added that the plan did not anticipate, and it changes results.**
A cross-genome edge requires the producing GIFT's output anchor to be declared
`extracellular`. Without it, the arabinoxylan fixture produced edges C → D and
D → C through `XYLOSE_IN` — a **cytoplasmic** anchor — which asserts that one
organism hands another a molecule that never leaves a cell. A `cytoplasmic`
anchor is inside one cell by construction and an `unspecified` one was never
evidenced as leaving it, so neither licenses a transfer. The same link inside a
single genome is an ordinary composition step and is still reported as one,
which is why `chain_coverage` gained the `not_transferable` status: when the two
halves of an internal link fall in different genomes, nothing completes it, and
calling that distributed would be exactly the error the anchor compartment
qualifier exists to prevent. Distributed cycle closure carries the same
restriction and therefore reports `not_closed` for the oxidative citric acid
cycle however the community is composed, because central metabolism runs on
intermediates that never leave a cell.

With the rule in place the fixture yields the three edges the design predicted —
A → B, B → C, B → D — and no others.

49 new tests in `test-community-network.R`; full suite green at 3538.

### 2026-08-19T04:20Z — Genome-resolved communities and distributional traits

**Change.** Two new exported functions, `gifter_community()` and
`community_traits()`, in the new `R/community.R`. **No schema, database content
or evaluation change.** This is phase 2 of
`inst/doc/proposal-quantitative-traits.md`.

**Why.** Every community question — how redundantly is a capability provided,
which genome is its only provider, how much of the sampled abundance carries it
— needs a container that holds several genomes' calls at once, and
`evaluate_gifts()` evaluates one annotation table. The externally drafted
proposal assumed such an object into existence without defining it, which is
why defining it is a phase of its own rather than a detail of the metrics.

**Effect.** `gifter_community()` binds named results into one call matrix and
refuses two comparisons that are not comparable: genomes evaluated against
different database releases, because a provider count over two releases counts
capabilities that were not offered to every genome, and an abundance vector
that does not name exactly the supplied genomes. A GIFT missing from a genome's
result is not supported, so a filtered evaluation cannot claim a capability it
never tested.

`community_traits()` reports `community_richness`, `community_coverage` for
bounded universes, `mean_genome_richness` beside it rather than divided into
it, `provider_count` per GIFT, `abundance_coverage` per GIFT when abundance was
supplied, `singleton_fraction`, `unique_contribution` per genome and
`repertoire_overlap` per genome pair — all within every supplied universe, in
the same long-form shape phase 1 established, with `target_type` distinguishing
community, GIFT, genome and genome-pair rows.

Presence and abundance never merge. `provider_count` and `abundance_coverage`
are separate rows with separate units, because how many genomes encode a
capability and how much of the observed abundance they represent answer
different questions and neither is a statement about activity. Overlap is
computed within a universe rather than only across the catalogue: 94% of the
GIFTs are metabolic, so an unstratified Jaccard index is a metabolic overlap
under a general name. Where both genomes of a pair hold nothing in a universe
the overlap is withheld rather than reported as zero, since reporting zero
would say two repertoires were compared and found to share nothing.

The arabinoxylan chain is the integration fixture and it is curated, not
invented: `arabinoxylan_debranching -> xylan_degradation -> xylose_uptake_abc ->
xylose_degradation_isomerase` are already connected in `gift_graph`. Its marker
sets are chosen so each genome completes exactly the intended capabilities,
which the first test checks rather than assumes — several CAZy families
evidence both debranching and backbone cleavage, and a careless fixture would
give one genome two capabilities and destroy every expected provider count.

54 new tests in `test-community-traits.R`; full suite green at 3489.

### 2026-08-19T03:55Z — Reference universes and quantitative genome traits

**Change.** Two new exported functions, `gift_universe()` and
`genome_traits()`, in the new `R/universe.R` and `R/traits.R`. **No schema,
database content or evaluation change**: the database is byte-identical and no
call moves. This is phase 1 of
`inst/doc/proposal-quantitative-traits.md`.

**Why.** The architecture guide's *Derived capabilities* section already
promised this layer — "a derived layer would read their calls rather than
adding a fifth type" — and invariant 18 requires higher-order descriptions to
be derived from primary typed GIFTs rather than curated as one. With 130 GIFTs
the question "how many, of what kind, how distributed" is now worth asking, and
asking it without a declared denominator is what makes such numbers
untrustworthy. A count of supported GIFTs is meaningless without the set it was
counted over, and that set changes between releases.

**Effect.** `gift_universe()` builds a reference universe from curated metadata
only — `gift_type`, `mode`, the registered facet vocabulary, and the derived
`gift_profile` view. A universe may not be a list of `gift_id`s written in R,
which is invariant 10 applied one layer up. `genome_traits()` reports
`gift_richness`, `breadth_*` over every facet and profile classification,
`handoff_out_degree` and `handoff_in_degree` from `gift_graph`,
`multi_implementation_gifts` and `closed_cycles`, each within every supplied
universe, as a long-form table carrying `numerator`, `denominator`,
`assessable`, `reference_universe` and `database_version`, plus a `trace` table
naming the GIFTs behind every row.

Three refusals are built into the behaviour rather than left to documentation.
`supported_fraction` is reported **only** for a universe explicitly declared
`bounded`, because a fraction of an open and growing catalogue reads as the
share of microbial function a genome carries; the default set bounds exactly
one universe, the biomass-essential anabolic GIFTs, over which the fraction is
biosynthetic capability coverage. Handoff degrees are withheld from a universe
that does not reach the metabolic model, because a structural GIFT declares no
anchors and reporting zero would imply a test the genome failed. And traits
computed against a database version other than the one that produced the calls
are an error, not a warning.

`assessable` currently equals the size of the universe: gifter accepts no
genome-quality information, so every member is treated as assessed. That column
exists now so its shape is stable when phase 4 adds the assessability policy.
Nothing in this layer can change a Boolean call, and `closed_cycles` reads
`evaluate_gift_cycles()`, which already guarantees the same.

81 new tests in `test-universes.R` and `test-genome-traits.R`; full suite green
at 3435.

### 2026-08-19T13:10Z — Mercury detoxification curated: the first defense GIFT that is not anti-phage

**Change.** Database version **2026.19.1**, schema unchanged at 6, **no R code
change**. One defense GIFT, `mercury_detoxification`, with one mechanism
(`MECH_MER_HG`), four defense functions, six systems, seven components and eight
markers, plus the `defense_class` value `chemical_detoxification`. 129 GIFTs
become 130.

**Why.** The assessment is `inst/doc/proposal-aromatic-degradation.md` §8.8, its
class decision §10.6, and its implementation record §17. Hg(II) reduction has a
Rhea master but no honest `mode`: it is not a directed conversion between
nutrient anchors, and a fifth mode invented for one trait would put mercury into
the anchor graph as edges through metal-ion anchors that mean nothing. The
defense contract already covers a chemical challenge, and the machinery model
supplies the required-and-accessory distinction the *mer* operon needs.

**Effect.** MerA alone completes the call, because a genome carrying *merA*
detoxifies the Hg(II) that reaches its cytoplasm; requiring *merT* and *merP*
would refuse the genomes whose operon is built around *merC* or *merE*. Delivery,
induction and organomercurial lysis are accessory and report as unsupported
without changing the call. `TIGR02053` stands beside `K00520` as an alternative
at `high-confidence`, so a genome hit only by the NCBIfam family calls the GIFT
complete at the weaker confidence. Three refusals are recorded rather than left
implicit: `NF033555` and the InterPro entries, because the evidence layer
normalises KO, EC, Pfam, TIGRFAM, CAZy and custom HMMs only and an unmatchable
accession reads as evidence; `K19057` (MerD), because it is a co-regulator and
evidence rows are alternatives, so it would let a genome with no activator claim
induction; and mercury methylation (*hgcAB*), which makes mercury more toxic and
is a different capability. Three `database_changes.tsv` records carry the
decisions. Five new tests in `test-regulatory-defense.R` and four inventory
expectations updated; full suite green at 3354.

### 2026-08-19T12:30Z — Assessment: the mercury defense class is named for the mechanism

**Change.** Documentation only. `inst/doc/proposal-aromatic-degradation.md`
gains §10.6 and resolves its open question §14.3: the `defense_class` value
§8.8 needs is **`chemical_detoxification`**, not `metal_detoxification` and not
a resistance class. **No code, schema, database content or facet registration** —
mercury is still uncurated, and a facet vocabulary is registered when the first
content needing it is curated.

**Why.** `defense_class` is single-valued and partitions the defense type, so
the name is the bucket every future defense GIFT falls into exactly once, and
the way to choose it is to write out what each candidate would have to hold.
A resistance class fails three ways: its roster is mostly *not* defense GIFTs
(metal efflux is transport, MerR and CmtR are regulatory, lipid A modification
is structural); resistance is an outcome, which `proposal-defense-gifts.md`
refuses twice and which §15 of the aromatic proposal already disclaims for this
very GIFT; and invariant 18 puts phenotypic descriptions in a derived layer. The
curated vocabulary says the same thing already — `restriction_modification` and
`crispr_cas` are both anti-phage and were deliberately not merged into
`phage_resistance`. `metal_detoxification` fails differently: it holds three
curatable members ever, because ArsM has no orthology group, ChrR's group is a
generic NAD(P)H:quinone dehydrogenase, and ArsC's product is *more* toxic than
its substrate.

**Effect.** Mercury will be curated with `defense_class = chemical_detoxification`
when §8.8 is implemented. The class is defined by a mechanism test — enzymatic
conversion of a toxic chemical into a less harmful species — which excludes
efflux, sequestration and repair by construction, and admits a populated roster
of markable future members: SOD and catalase, AhpC and Ohr, Hmp and NorV, GloAB,
FrmAB, TehB and CueO. Two follow-ons are recorded rather than decided: a
separate multi-valued `challenge_class` facet if the "against what" axis is ever
needed, and the §10.3 test applied a second time to formaldehyde, which is
detoxification in most organisms and carbon metabolism in methylotrophs.

### 2026-08-19T05:10Z — `gift_cycles()` stops reporting direction reversals as cycles

**Change.** `gift_cycles()` excludes any elementary cycle whose members include
both an `anabolic` and a `catabolic` GIFT, alongside the two-node
`interconversion` loop it already excluded. `evaluate_gift_cycles()` follows,
because it reads what `gift_cycles()` derives. The accessor documents both
exclusions, and `R/cycles.R` records why.

**Why.** The amino acid layer curates both directions for arginine, proline,
threonine, cysteine and methionine, and every such pair closes a ring in the
composition graph. A ring that alternates modes says a genome can both build a
metabolite and break it down — which the composition rule already treats as
expected, and is why the source validator checks acyclicity per mode — so it is
not circular metabolism. It is also not harmless to report: the mixed rings
combine, and before the exclusion the enumeration returned a truncated list of
100 in which the oxidative citric acid cycle appeared at position 34.

**Effect.** `gift_cycles()` returns one cycle for the curated database, the
oxidative citric acid cycle, as it did before the amino acid layer. No GIFT call
changes: closure never fed back into a call. Edges are untouched — the exclusion
is about what counts as a cycle, not about what counts as composition.

### 2026-08-19T05:00Z — Amino acid metabolism curated: 28 GIFTs

**Change.** Database version **2026.19.1**. The fifteen proteinogenic amino
acids gifter did not cover are curated as eighteen composable biosynthesis GIFTs,
and amino acid degradation arrives with ten more. Schema unchanged at 6; no R
change other than the cycle exclusion above.

**Why.** The assessment is `inst/doc/proposal-amino-acid-metabolism.md`, whose
§16 records where the implementation departed from it. Six boundaries are
gifter's own rather than KEGG's, each at a branchpoint where genomes measurably
differ — meso-diaminopimelate, the two branched-chain 2-oxo acids, threonine
deamination as catabolism, glutamine as its own capability, and the widened
aromatic transaminase.

**Effect.** 89 GIFTs become 129 and 109 anchors become 140. Four boundaries that
were declared inputs with no producer gain one — L-aspartate, L-glutamine,
3-methyl-2-oxobutanoate and hydrogen sulfide — so pantothenate, pyrimidine,
pyridoxal phosphate and the two sulfide-dependent biosynthesis GIFTs stop
hanging off the graph. `auxotrophy_indicator` now reports on all twenty amino
acids rather than five. No existing GIFT call changes: no curated route, system,
component or marker was edited, with one correction: L-aspartate and
L-glutamine were marked `biomass_essential = no` from when they existed only as
input boundaries, and both are proteinogenic. Seven `database_changes.tsv`
records carry the biological decisions, including that correction, the
deliberate under-call of cysteine desulfidation and the promotion of acetyl
phosphate to an anchor.

### 2026-08-19T11:20Z — Aerobic aromatic ring catabolism curated; mercury carved out

The assessment is `inst/doc/proposal-aromatic-degradation.md`, whose §16 records
the implementation. **No code change and no schema change** — this is a content
release, database version 2026.19.1, and the proposal's first claim was that the
layer needed neither.

Twelve metabolic GIFTs, twelve anchors, thirty reactions and forty-nine markers.
Three peripheral entries (benzoate, anthranilate, phenol) converge on catechol,
both cleavage strategies leave it, the aerobic phenylacetate route joins at the
3-oxoadipyl-CoA thioester, and the phenylpropanoid node feeds the shared lower
route. Thirteen composition edges, all through declared anchors.

**Mercury was carved out** at the user's direction and is being assessed
separately, so no defense GIFT and no `defense_class` facet value were
added. Fourteen of the twenty-four candidates assessed stay refused, nine of
them because no marker in any namespace resolves which ring a Rieske dioxygenase
hydroxylates; the register is `DBC-20260819-AROMATIC-REFUSALS`.

Four decisions worth reading in the proposal's §16.

- **Where KEGG bundles, gifter cuts.** The lower *meta* route that five modules
  duplicate is curated once as `oxopentenoate_degradation`; the thiolysis that
  ends both the ortho funnel and the phenylacetate route is curated once as
  `oxoadipyl_coa_thiolysis`; and M00545, which ORs two different input
  substrates into one module, becomes three GIFTs around a shared anchor,
  because a route must connect its own GIFT's boundaries.
- **`K07104` is refused** as evidence of catechol 2,3-dioxygenase: 2081 genomes,
  led by Firmicutes that do not degrade aromatics, only 276 of which carry any
  lower *meta* gene. A test pins the refusal in both branches.
- **Shared Rieske ferredoxin and reductase subunits are deliberately not curated
  as components**, because `enzyme_component` has no `required` flag and those
  subunits are annotated two to three times less often than the subunits they
  serve. The omission is stated in each system description, and a test proves the
  excluded reductase is inert.
- **One predicted broadening did not happen.** Adding MhpF and XylQ as
  alternative systems of the acetaldehyde dehydrogenase reaction was expected to
  broaden `ethanol_formation`; measurement showed it does not, because that
  route's second reaction rests on AdhE alone. The change record was corrected
  from `broadens` to `none`.

`tests/testthat/test-aromatic.R` adds 209 assertions. Two existing tests were
updated because the new content is genuinely visible to them: `test-scfa.R` now
expects the aromatic funnel among acetyl-CoA producers, and `test-organic-acid.R`
admits one non-cycle producer of succinate while keeping its guard that no
`_formation` trait may produce it.

### 2026-08-19T00:20Z — Shikimate-derived aromatic biosynthesis curated

The assessment is `inst/doc/proposal-shikimate-aromatics.md`. Three metabolic
GIFTs added, one candidate refused, database version **2026.17.1**.

**Change.** `chorismate_biosynthesis` (PEP + erythrose 4-phosphate to
chorismate, 7644 of 10 151 bacteria and 90 of 470 archaea),
`salicylate_biosynthesis` (chorismate to salicylate, 646 bacteria) and
`indole_3_acetate_biosynthesis` (L-tryptophan to the auxin, 86 bacteria) are
curated over ten new reactions, all with Rhea masters. `gallate_biosynthesis` is
refused. A `biosynthetic_family` facet is registered and
`shikimate_derived_aromatic` assigned to the three new GIFTs and to
`paba_biosynthesis` and `menaquinone_biosynthesis`. No schema migration and no R
change.

**Four decisions are worth reading.**

- **The family is a facet, not a GIFT.** "Aromatic compound biosynthesis" cannot
  be one capability: two of the four candidates do not have chorismate on either
  side of the arrow, so a single GIFT would have to declare boundaries no route
  connects. `substrate_class` was deliberately not reused for the grouping —
  the five GIFTs carrying the new value hold two different substrate classes
  between them, which is the demonstration that the facets are orthogonal rather
  than redundant.
- **The shikimate dehydrogenase step is curated as not required.** `K00014`
  reaches 5585 bacteria where every other step of the pathway reaches 8461 to
  9149, and requiring it removes 201 of 213 Cyanobacteriota and 1061 of 1642
  Actinomycetota. *M. tuberculosis* Rv2552c and *Synechocystis* slr1559 are
  annotated shikimate 5-dehydrogenase in RefSeq and carry no KO at all. This is
  the vitamin layer's orphan-step rule applied to a marker with a taxonomic hole
  rather than a specificity problem, and `TIGR00507` is added alongside `K00014`
  so an InterPro-annotated genome can satisfy the step — the first metabolic
  marker added for coverage rather than for specificity.
- **MbtI is a system, not a route.** The bifunctional salicylate synthases run
  the same two transformations as PchA and PchB, with the isochorismate
  enzyme-bound rather than released, so they belong at the system layer exactly
  as the bifunctional PabBC already does. Because systems attach to reactions
  rather than routes, accepting PchA and MbtI for `RHEA:18985` also reaches the
  menaquinone route; that was measured before the decision and adds 7 genomes.
- **Three of four auxin routes are refused.** The indole-3-pyruvate, tryptamine
  and nitrile routes are real chemistry whose markers cannot distinguish auxin
  formation from ordinary transamination, decarboxylation or aldehyde oxidation.
  `K04103` is the sharpest case: 417 of its 648 bacterial carriers are
  Enterobacteria and KEGG assigns it in *Salmonella* to a protein annotated only
  as a putative thiamine pyrophosphate enzyme.

**Gallate fails earlier than the specificity question.** Rhea records gallate in
nine reactions and **none forms it from 3-dehydroshikimate**; there is no EC
number for the transformation and no KO, TIGRFAM or Pfam family for a
gallate-forming dehydrogenase. With no reaction identity there is nothing to
curate, and the only enzymes described as doing it are plant shikimate
dehydrogenases whose markers are the AroE markers of the core pathway. A curated
`CUSTOM_HMM` could not rescue it today either: the characterised sequences are
plant, so there is nothing bacterial to train on. Gallate release from
hydrolysable tannins by tannase (`K10759`, EC 3.1.1.20) is different chemistry
between different boundaries and is deferred, not refused.

**Effect.** `paba_biosynthesis` and `menaquinone_biosynthesis` gain an upstream
neighbour and move from `entry` to `intermediate` in `gift_profile`; `CHORISMATE`
is the first of the four orphan input anchors named in the amino acid assessment
to close. `indole_3_acetate_biosynthesis` reports as `isolated`, which is the
correct answer while nothing in gifter produces tryptophan. Three inventory
assertions in `test-database.R` — the GIFT roster, the shared-anchor set and the
database version — were refreshed against the compiled database.

### 2026-08-19T00:05Z — Assessment: the rest of amino acid metabolism

The assessment is `inst/doc/proposal-amino-acid-metabolism.md`. **No code,
schema or biological content change** — this entry records that the layer was
tested and what the test found.

**Change.** The fifteen proteinogenic amino acids gifter does not curate, plus
amino acid degradation and microbial transformation for all twenty, were tested
against KEGG orthology over the 10 151 bacterial genomes of KEGG, Rhea 141 and
ChEBI 253. Twenty biosynthesis GIFTs and ten degradation or transformation GIFTs
are recommended, six candidates are deferred pending a boundary decision
elsewhere, and six are refused as named. No schema migration and no R change is
required by any of it.

**Four findings are worth reading even if the layer is never curated.**

- **The amino-donor rule.** Glutamate is a co-substrate of nearly every reaction
  in the layer. Declaring it an anchor wherever it is consumed would give
  sixteen new GIFTs an edge from one node and turn `gift_graph()` into a star.
  The rule — the nitrogen donor of a transamination is never an anchor, the
  nitrogen source of an assimilation always is — is the nitrogen analogue of the
  sulfur split the methionine and cysteine GIFTs already encode.
- **An assimilatory cycle cannot be decomposed by anchors.** GS and GOGAT form a
  genuine cycle between two anabolic capabilities, and `.find_graph_cycle()`
  rejects anabolic cycles by design. The citric acid cycle could be cut only
  because two of its four segments are `interconversion`; here the cycle has to
  live inside one GIFT. This is the first case where real biology collides with
  the acyclicity rule rather than exposing a bad boundary.
- **KEGG's amino acid modules under-call by construction, measurably.** The four
  lysine modules score 51.4%, 5.6%, 6.8% and 17.2% separately and 75.3% as
  alternative routes of one capability. Requiring KEGG's aromatic
  aminotransferase calls phenylalanine biosynthesis in 2296 genomes where the
  discriminating aryl skeleton is present in 7796; widening the marker set to
  the aspartate and branched-chain aminotransferases recovers 7733, which shows
  the step carries no information rather than that it is missing.
- **Four orphan input anchors close.** `ASPARTATE`, `CHORISMATE`, `GLUTAMINE`
  and `OXOISOVALERATE` are declared as inputs today and produced by nothing, so
  pantothenate, folate, menaquinone and the aspartate family currently hang off
  the composition graph.

**Effect.** Documentation only. The assessment also reconciles two overlaps with
the assessments filed the same day: it adopts the nitrogen-anchor rule of
`proposal-nitrogen-compound-catabolism.md` unchanged, recommends that
`ammonium_assimilation` and `glutamate_biosynthesis` be one GIFT under one name,
corrects that assessment's ammonium assimilation prevalence from 9482 to 8686
genomes — glutamine synthetase without a glutamate synthase is not a net
assimilation route, and 796 genomes have exactly that — and records that the
`ACETYL_PHOSPHATE` anchor question can no longer be deferred, because glycine
reductase has no other product to declare and the validator requires an output
anchor.

### 2026-08-18T23:40Z — The overview networks become dots you point at

**Change.** The two networks on the atlas overview are no longer layered
diagrams of labelled boxes. Both are now drawn by `.report_dot_network_svg()`:
a GIFT is a large coral dot, an anchor a small mint dot, edges are hairlines,
and **nothing in the drawing carries text**. Pointing at a dot dims every node
and edge it is not connected to and opens a card next to it with the name, the
identifier, the declared boundaries, and the route and reaction counts;
clicking a GIFT dot opens it in the GIFT explorer, the same detail the summary
table opens. Dots are placed by `.report_force_layout()`, a deterministic
Fruchterman-Reingold sweep seeded on a golden-angle spiral, so the drawing is
identical between builds without carrying a random seed. Gravity is stronger
along the short axis, which settles the layout into an ellipse shaped like the
frame instead of a disc that has to be squashed into it.

**Why.** Both views were laid out in longest-path columns of 246-pixel boxes.
With 72 GIFTs and 89 anchors that is a canvas several thousand pixels wide,
scrolled sideways, where reading a name meant finding the box and reading the
structure meant losing it. The overview asks one question -- *how do these
traits connect* -- and the shape of the graph is the answer to it. Every label
that was printed on the canvas is still there, one hover away, and the layer
that actually names things, the GIFT explorer, is now one click from any dot.

**Effect.** Presentation only: no query, no call, and no curated row changed.
The per-GIFT route networks are untouched, and still draw labelled reaction
boxes, because there the labels *are* the content. Edge tooltips are gone from
the two overview networks -- what an edge asserts is now read off the two dots
it joins -- so the anchor network is tested through its `data-edge-from` and
`data-edge-to` attributes instead of through edge titles.

### 2026-08-18T23:10Z — Assessment: aromatic degradation and mercury, 21 requested capabilities

The assessment is `inst/doc/proposal-aromatic-degradation.md`. **No code, schema
or biological content change** — this is a recorded evaluation, and its main
result is a register of refusals.

The request was the 21 capabilities of KEGG's *Xenobiotics biodegradation*
module category plus mercury. Twenty-four candidates were tested against KEGG
orthology prevalence (11 949 genomes), Rhea, and InterPro/NCBIfam. Six are
recommended for curation, two conditionally, two deferred, and **fourteen
refused** — nine of them for one reason: substrate specificity in
ring-hydroxylating dioxygenases is not resolvable by any marker gifter can use,
and unlike the butyrate case in the SCFA proposal, no namespace change rescues
them. The families available are `IPR001663` and `PS00570`, which are the family
signature itself.

Four findings are worth reading even if the layer is never curated.

- **A KEGG module is not a GIFT, demonstrated twice by chemistry.** M00538
  attaches the *tmo* ring monooxygenase system to toluene → benzyl alcohol, but
  Rhea's master for the EC KEGG itself assigns that system is toluene →
  4-methylphenol; side-chain hydroxylation is a different enzyme in a different
  module. M00548 attaches a phenol 2-monooxygenase to benzene oxidation. Both
  were found only because gifter requires a Rhea master per reaction.
- **`enzyme_component` has no `required` flag, and this layer is the first
  content to want one.** Rieske ferredoxin and reductase subunits are shared,
  interchangeable and annotated 2–3× less often than the catalytic subunits they
  serve, so curating them under AND converts an annotation gap into a false
  negative. The proposal recommends solving it in curation rather than migrating
  the schema, and records the case as the strongest reason to revisit that.
- **Mercury belongs to the `defense` type, not to a fifth `mode`.** Hg(II)
  reduction is neither anabolic, catabolic, transport nor interconversion; the
  defense contract already covers a chemical challenge, and the machinery model
  already expresses the accessory *merTP*, *merR* and *merB* functions.
- **`K07104` is an over-broad marker** assigned in 2081 genomes dominated by
  Firmicutes that do not degrade aromatics, only 276 of which carry any lower
  *meta* pathway gene. The route logic would hide the damage inside one GIFT; the
  marker would still be in the database for the next one.

### 2026-08-18T23:50Z — Nitrogen compound catabolism curated

Database **2026.18.1**, schema 6 unchanged. **No code changed**; this entry
records the content release and the two architecture rules it required, both now
in `inst/doc/architecture.md`. The assessment is
`inst/doc/proposal-nitrogen-compound-catabolism.md`, whose §17 records the
implementation and every point where it departed from the proposal.

**Content.** Fourteen GIFTs: `urate_degradation`, `allantoin_degradation`,
`urea_hydrolysis`, `nitrate_assimilation`, `betaine_demethylation`,
`sarcosine_demethylation`, `creatinine_degradation`,
`carnitine_degradation_trimethylamine`, `carnitine_to_betaine`,
`methylamine_degradation`, `taurine_desulfonation_aerobic`,
`taurine_degradation_sulfoacetaldehyde`, `taurine_uptake_abc` and
`ammonium_assimilation`. Sixteen anchors, seven facet terms, 26 routes, 37
reactions, 39 enzyme systems, 55 components, 57 markers. `glcnac_degradation`
and `neuac_degradation` gained `AMMONIUM` as an output anchor, which changes no
call: both already ended at the deaminase that liberates it.

**Two rules are now in the architecture guide.** The **nitrogen-anchor rule**
admits ammonium as an anchor only where the reaction's purpose is to liberate or
assimilate it, and it sits beside the cofactor-anchor rule under *Keeping the
anchor vocabulary small*. The **electron-acceptor rule** is now an explicit item
in *What gifter deliberately does not model*, generalising the refusal that was
previously recorded only on the `FUMARATE` anchor.

**Three departures from the proposal, all found by checking Rhea before
curating.** The carnitine dehydrogenase route yields glycine betaine, not
trimethylamine — `RHEA:47044` makes the betainyl thioester and `RHEA:45716`
hydrolyses it — so it became its own GIFT and the trimethylamine claim narrowed
from 972 genomes to 271. The anaerobic taurine GIFT declares no ammonium,
because its two routes dispose of the nitrogen differently (alanine from the
transaminase, ammonium from the dehydrogenase) and a GIFT anchor must hold for
every route. `allantoin_degradation` declares none either, for the same reason.

**Tests.** `tests/testthat/test-nitrogen.R` adds 101 assertions, including the
negative cases that eleven respiratory accessions match no marker at all and
that a primary-amine oxidase does not fire a phenylethylamine trait. Four
existing inventory assertions moved for the new content: the compartment-split
molecule list, the no-external-link GIFT list, the dual-specificity importer
test (which filtered on `mode == "transport"` and so swept in the new taurine
importer), and the sugar-degradation downstream assertion, which now protects
what it was actually for — that no *carbon* anchor reaches a biosynthesis GIFT
— rather than forbidding the legitimate catabolic-to-anabolic ammonium edge.

### 2026-08-18T23:15Z — Nitrogen compound catabolism assessed

The assessment is `inst/doc/proposal-nitrogen-compound-catabolism.md`. **No
content was curated and no code changed**; this entry records that the layer was
tested, what the test found, and the two rules the layer cannot be curated
without.

**Change.** The twelve compounds of distillR 1.x bundle D06, "Nitrogen compound
degradation" — nitrate, urea, urate, GlcNAc, allantoin, creatinine, betaine,
L-carnitine, methylamine, phenylethylamine, hypotaurine and taurine — were
tested against KEGG orthology, Rhea 141, ChEBI 253 and the installed distillR
`GIFT_db`, over all 10 151 bacterial genomes in KEGG. Eleven GIFTs are
recommended and two more conditionally; two existing GIFTs gain an output
anchor; six traits and two routes are refused.

**Two rules are proposed, and the layer cannot be curated without either.** The
**nitrogen-anchor rule** admits `AMMONIUM` as an anchor only where a reaction
exists to liberate or assimilate it; applied to the database as it stands it
admits one of the four existing NH4+ reactions and rejects three, which is what
stops riboflavin and menaquinone biosynthesis becoming nitrogen sources and NAD
biosynthesis becoming a nitrogen sink. The **electron-acceptor rule** generalises
the refusal already recorded on the `FUMARATE` anchor: a capability whose
completion needs an external terminal electron acceptor is out of scope, which
refuses nitrate respiration, denitrification, DNRA and "taurine to hydrogen
sulfide" architecturally rather than evidentially.

**Two findings bear on how much weight the legacy database should carry.**
distillR's `D0613 Taurine` is defined in part by EC 2.5.1.55, which is KDO
8-phosphate synthase (`kdsA`, K01627), a lipopolysaccharide enzyme present in
5537 of 10 151 bacteria — almost certainly a transposed digit for 2.5.1.76,
cysteate synthase, at 39. And `D0612 Hypotaurine` is defined by a taurine
enzyme plus a generic aldehyde dehydrogenase, so it cannot distinguish the two
compounds. Neither is an argument against distillR, which used a different
primitive; both are arguments for the existing rule that the legacy database is
a coverage checklist and never an evidence source.

**One correction is owed to `SOURCES.md`.** MetaCyc is reachable again through
`websvc.biocyc.org/getxml` for records addressed by ID, so the recorded reason
for not citing it — subscription gating — is now wrong. gifter still cites no
MetaCyc row, and the proposal's §4 gives the structural reason that does not
depend on access.

### 2026-08-18T21:30Z — Circular central metabolism, and a scope fix for the acyclicity check

The assessment is `inst/doc/proposal-central-metabolic-cycles.md`. It recommends
option 1 of the three it evaluates: atomic segment GIFTs plus **derived** cycle
detection, with no schema migration and no circuit table. The schema stays at
version 6.

**The within-mode acyclicity check is now scoped to the directed modes.** This
is a bug fix and is independent of any citric acid cycle content. The
`interconversion` mode requires every anchor to be declared in both roles, so
two interconversion GIFTs that share one anchor produce an edge in each
direction *by construction*; the check reported that as a circular composition
error. Two synthetic reversible GIFTs sharing one fixture anchor reproduce it
with no biology involved. `.gifter_directed_gift_modes` now names the three modes
that declare a direction, and the scan iterates those. Loops in `anabolic`,
`catabolic` and `transport` are still errors, which `test-composition.R` asserts
alongside the new exemption.

**`gift_cycles()` derives the elementary cycles of the composition graph.** It
is graph code with no biology in it: the oxidative citric acid cycle falls out
of four curated anchor declarations, and the same function will find the
reductive cycle, the glyoxylate bypass or the Calvin cycle when those are
curated. A two-node loop between two reversible GIFTs is excluded, for the same
reason the validator exempts it. Enumeration is bounded by `limit` and warns
rather than running unbounded.

**`evaluate_gift_cycles()` reports closure for a genome** — `closed`, `open`
with the unsupported members named, or `absent` — from an `evaluate_gifts()`
result. It never changes a call. A segment is complete on its own routes and
markers whether or not its neighbours are, and a `closed` cycle is a statement
about encoded chemistry rather than about flux, direction or expression.

The only curated part of a cycle is its name, which is a new multi-valued GIFT
facet, `metabolic_cycle`. Structure is derived and naming is curated, so the two
cannot drift apart.

`R/cycles.R` is new. `R/database-build.R` gained the mode constant and the
scoped scan. `inst/doc/architecture.md` gained a "Cycles in the composition
graph" section and AGENTS.md invariant 8 was rewritten. Biological content is
recorded separately, as `DBC-20260818-CENTRAL-CYCLE-LAYER`.

### 2026-08-18T20:30Z — Vitamin biosynthesis curated

The assessment is `inst/doc/proposal-vitamin-biosynthesis.md`, whose §14 records
what implementation changed. **No schema and no R change** — the layer is a
content release, 2026.15.1, and the proposal's first claim was that it could be.

**Change.** Twenty GIFTs covering vitamins B1, B2, B3, B5, B6, B7, B9, B12 and
K2: 31 anchors, 26 routes, 94 Rhea-mastered reactions, 104 enzyme systems and
151 marker assignments. `substrate_class` gains `cofactor`,
`physiological_role` gains `vitamin_biosynthesis`, and `resource_origin` gains
`microbially_derived` for the precursors a genome acquires from its neighbours.
Thirteen `database_changes` entries accompany it, eleven of which record a
refusal or a boundary decision rather than an addition.

**What the layer refuses to say.** A single "produces vitamin B12" trait is
refused twice over. 4139 of 10 151 bacterial genomes complete the cobamide
nucleotide loop and 3044 of those encode no corrin ring at all, so the loop is
curated as its own capability and a positive call on it is not a production
claim; and of the 1081 genomes that do complete ring, cobinamide arm and loop,
only 538 carry BluB, without which the product is a cobamide rather than the
vitamin. `dmb_biosynthesis_aerobic` is therefore separate, and a negative call
on it is explicitly not evidence that the genome cannot make the ligand, because
the anaerobic route has no orthology group.

**The orphan-step rule, and why it needed a test.** Four reactions in the layer
are certain chemistry with no marker at the specificity of the step. They are
curated with `required = 0` rather than deleted or evidenced by a widened
marker: requiring the riboflavin phosphatase would drop that trait from 7943 to
2682 bacterial genomes, and requiring the folate pyrophosphatase would drop
folate from 5898 to 1634. Two of the four — MenH and the DHNA-CoA thioesterase —
were curated as required in the first pass, which made *Bacteroides*-profile
genomes menaquinone-negative, and `tests/testthat/test-vitamins.R` caught it.

**Effect on users.** Twenty new callable GIFTs and 13 new composition edges, all
internal to the layer. `gift_profile()` reports `cross_feeding_output` as 0 and
`resource_strategy` as `private` for all twenty, because no vitamin transporter
is evidenceable, and `auxotrophy_indicator` as 1 for the twelve whose output is
a biomass-essential boundary. No existing GIFT call changes. `list_gifts()`
returns 68 rows, and the packaged database is version 2026.15.1.

### 2026-08-18T18:00Z — Organic acid formation curated

The assessment is `inst/doc/proposal-organic-acid-formation.md`. **No code
changed and the schema stays at 6**; this entry records what the content release
2026.14.1 added and, more usefully, what it refused.

**Change.** Six GIFTs: `lactate_formation`, `lactate_racemisation`,
`malolactic_fermentation`, `citrate_fermentation`, `ethanol_formation` and
`acetoin_formation`. Five anchors, nine Rhea-mastered reactions, twelve KO
markers. `substrate_class` gains `organic_acid` and
`neutral_fermentation_product`; `physiological_role` `fermentative_end_product`
is broadened from short-chain fatty acids to fermentation end products
generally.

**Why the request split in half.** The layer began as a request to express the
capacity to form fumarate, succinate, citrate and lactate. Those four are not
one class. Lactate is a fermentation end product a genome can be said to
release; the other three are citric acid cycle intermediates, consumed by the
pathway that makes them and present in every genome that has the cycle. Five
candidates are refused and the refusals are in `database_changes.tsv`:

- *Succinate.* On `frdABCD` it calls *Vibrio*, *Escherichia* and *Klebsiella*
  positive — fumarate respirers — and *Bacteroides*, *Prevotella* and
  *Fibrobacter* negative. Allowing the fused group instead fires in 7276 of
  11 855 organisms including *Chlamydia*. KEGG names that group `sdhA, frdA`.
- *Fumarate.* `K01756` is in 11 115 organisms, and gifter already curates the
  fumarate-releasing chemistry inside `purine_core_biosynthesis` and
  `adenylate_biosynthesis`.
- *Citrate synthesis.* `K01647` is in 8467 organisms; the trait would mean "has
  a citric acid cycle". The catabolic direction is curated instead.
- *Formate.* Refused on architecture, not evidence: `gift_anchor` is keyed on
  gift, role and ordinal, so declaring `FORMATE` on `pyruvate_to_acetyl_coa`
  would claim that all three of its routes produce it.
- *D-lactate formation.* Deferred; the (R)-lactate anchor is reached through the
  racemase, which is what the acrylate-route organisms actually do.

**The one result worth carrying forward.** `lactate_formation` is the first
fermentation end product in gifter whose direction is *evidenced* rather than
asserted. Acetate had to become an interconversion because Pta–AckA runs both
ways on one pair of genes; lactate does not, because forming it is an
NADH-consuming reduction and consuming it feeds a quinone or a cytochrome, and
KEGG gives those different orthology groups. 4143 organisms carry `K00016` and
3388 carry `K29125`, but only 573 carry both.

**A structural finding that outlives the layer.** Anchoring the citric acid
cycle closes a within-mode loop in anchor-derived composition and the build
fails — checked against `.find_graph_cycle()`, not predicted. There is no weak
boundary to demote the way `HOMOCYSTEINE` was, because no acid in the cycle is
only ever consumed. The constructive half is that a metabolite does not need an
anchor to be modelled: `citrate_fermentation` passes through oxaloacetate
without anchoring it, and malate and citrate enter as input-only boundaries.
`tests/testthat/test-organic-acid.R` asserts that no cycle metabolite is a
declared output anchor, which is the only durable protection against the
finding being rediscovered the expensive way.

**Tests that had to move.** `test-sugar-degradation.R` asserted the exact set of
GIFTs downstream of sugar catabolism; that set grows whenever a
pyruvate-consuming capability is curated, so it now asserts what the test was
actually protecting — the shared anchors and the downstream mode. Four
inventory assertions in `test-database.R`, one in `test-pathway-links.R` and one
in `test-scfa.R` were updated for the new content.

### 2026-08-18T17:00Z — Vitamin biosynthesis assessed

The assessment is `inst/doc/proposal-vitamin-biosynthesis.md`. **No content was
curated and no code changed**; this entry records that the layer was tested and
what the test found, so the next content release starts from the evidence rather
than from KEGG's module list.

**Change.** Candidate vitamin biosynthesis traits spanning twelve vitamins —
B1, B2, B3, B5, B6, B7, B9, B12, K2, C, E and provitamin A — were tested against
KEGG orthology, KEGG modules, Rhea, ChEBI and Pfam, over all 10 151 bacterial
genomes in KEGG and a panel of 18 reference genomes. Nineteen GIFTs are
recommended across nine vitamins; twelve further candidates are refused or
deferred. The proposal's five open questions were resolved the same day and are
recorded as §13 of the document: `GTP` is accepted as an input-only anchor and
the `GMP` link is deliberately left open, matching the `UMP`/`UTP` gap the
curated content already carries; the layer takes `substrate_class = cofactor`
with `physiological_role = vitamin_biosynthesis`, since the build enforces the
first as single-valued; menaquinone gets one anchor and a required MenG step;
the flavin kinase step stays uncurated; and `namn_salvage_nicotinate` is in the
first release.

**Why it is worth reading before the next content release.** The layer needs no
schema migration and no R change, and it is the first candidate layer whose
binding constraint is *per-step* evidence rather than per-trait evidence:

- *KEGG module definitions are not curatable boundaries here.* M00125 defines
  riboflavin completeness without lumazine synthase or riboflavin synthase,
  M00119 defines pantothenate without PanC or PanD, and M00127 defines thiamine
  as ThiF+ThiS+ThiI. Three of nine vitamins have a module whose `DEFINITION`
  omits the step the pathway is named for.
- *The orphan step is a new failure mode with a measured cost.* Four reactions
  in the layer are certainly present and have no marker at the specificity of
  the step. Requiring the riboflavin phosphatase drops that trait from 7943
  bacterial genomes to 2682; requiring the folate dihydroneopterin triphosphate
  pyrophosphatase drops folate from 5898 to 1634. The proposal recommends
  `route_reaction.required = 0`, which the schema already allows and three
  curated rows already use, and refuses the alternative of widening the marker —
  alkaline phosphatase (K01077, 3202 bacteria) is not evidence of a folate step.
- *"Produces vitamin B12" must be refused as named.* 4139 genomes complete the
  nucleotide loop and 3044 of them have no corrin ring, so a single trait would
  call salvagers producers; and of the 1081 that do complete ring, cobinamide
  and loop, only 538 carry BluB, without which the product is a cobamide rather
  than cobalamin. Four narrower GIFTs are proposed instead, including the first
  curated use of `gift_route.oxygen_requirement = 'aerobic'` for the aerobic
  corrin ring.
- *One architectural rule has to be set before the first anchor is added.* A
  cofactor may be declared an input anchor only where the reaction consumes it —
  FMNH2 by BluB — and never where it is recycled catalytically. Without it, THF,
  PLP and NAD become input anchors across the database and the anabolic
  acyclicity check stops describing biosynthetic composition.

**Effect on users.** None yet. No GIFT, route, reaction, marker or call changed.

### 2026-08-18T15:30Z — The atlas draws a reversible boundary as reversible

**Change.** `R/database-visualization.R` gains `.report_boundary_sides()`, which
decides what to draw on each side of a metabolic GIFT and which arrow to put
between them. For a directed GIFT nothing changes. For an interconversion GIFT
each anchor is drawn **once**, on the side where it was declared first, the
arrow becomes `&harr;`, the side labels become "Inputs / outputs" and
"Outputs / inputs", and the chips are coloured as shared boundaries rather than
as an input and an output.

**Why.** Declaring both directions made the renderer print the roles verbatim:

```text
before   ACETYL_COA ACETATE  ->  ACETATE ACETYL_COA
after    ACETYL_COA          <->  ACETATE
```

The old rendering was not merely redundant. A one-way arrow between two
identical sets asserts exactly the direction the mode exists to deny, so the
picture contradicted the data it was drawn from.

**The same defect in two other places.** In the whole-database anchor network an
interconversion GIFT was drawing two opposing edges between the same pair of
nodes, which reads as a contradiction rather than as reversibility. `.graph_edges()`
now takes a `bidirectional` flag, every graph defines a mirrored arrowhead
alongside its forward one, and the pair collapses to a single edge with a head
at each end, titled "is an input and output boundary of". The per-GIFT route
network carries the flag through the whole chain, so a reversible capability is
drawn boundary to boundary in both directions rather than pointing one way while
its own boundary display points both.

Each reaction keeps its `forward` / `reverse` badge, and the caption now says
why that is not a contradiction: the badge is the step's orientation relative to
its own Rhea master equation, which is a different question from which way the
capability runs.

**Effect.** Presentation only: no query, no call, no curated row changed. The
anchor filter chips still key on the declared roles, so an interconversion GIFT
is found by searching either boundary in either direction.

### 2026-08-18T15:00Z — The interconversion mode gains a boundary contract

**Change.** `R/database-build.R` now separates three ways a molecule can appear
on both sides of a boundary, and uses `mode` to say which is meant:

```text
same anchor, so one molecule in one compartment   reversible node   interconversion only
different anchors of one molecule, two compartments   translocation   transport
neither                                               directed chemistry
```

Two rules follow, both enforced: a GIFT that is not an interconversion may not
declare an anchor as both input and output, and an interconversion GIFT must
declare **every** anchor that way. `acetate_formation` is renamed
`acetate_interconversion` and now declares `ACETYL_COA` and `ACETATE` in both
roles. The SQL schema is unchanged at version 6 — this is a source-contract
rule, not DDL.

**Why.** `interconversion` had been a `CHECK` value with nothing behind it and
no written meaning. Curating the first GIFT that uses it is the point at which
the contract has to exist, and the honest contract turned out to be
bidirectional boundaries: the phosphotransacetylase and acetate kinase pair runs
both ways in different organisms, and no marker says which, so declaring one
direction asserts what the evidence cannot support while splitting the GIFT in
two asserts a distinction the same genes cannot make.

**What was at risk and how it was kept.** The rule being relaxed was doing real
work: "the same molecule is input and output" was the *definition* of transport,
and that is what makes transport required to reach the cytoplasm. Keying
translocation on a compartment *difference* preserves it and sharpens it, so a
reversible node in one compartment can never be mistaken for a transporter.
Four fixtures in `test-compartment.R` pin all four cases, including the negative
ones.

**Effect.** One new edge in `gift_graph`: `acetate_interconversion` now reaches
`butyrate_formation` through `ACETYL_COA` as well as `ACETATE`. No call changes,
no route changes, and no mirrored route was added — a flipped copy would
complete on identical markers and make closest-route selection
non-deterministic, so direction stays in the anchors for composition and in
`route_reaction.orientation` for chemistry. `inst/doc/architecture.md` documents
the split, including the point that `orientation` is relative to how Rhea writes
each equation and not to the direction of the GIFT.

### 2026-08-18T14:30Z — Short-chain fatty acid formation curated

**Change.** Six GIFTs are curated: `pyruvate_to_acetyl_coa`, `acetate_interconversion`,
`butyrate_formation`, `propanediol_formation`,
`propionate_formation_propanediol` and `propionate_formation_acrylate`.
Database version moves to 2026.13.1. **The SQL schema is unchanged at version
6.** One R change went with it, described in the entry below; the curated
content itself needed none. The biological decisions, their evidence and their effect
are in `database_changes.tsv`, readable with `database_changelog()`; the source
provenance and the four refusals are in
`inst/extdata/database-source/SOURCES.md`.

**Code.** None for the content itself, which is the entry's most useful line.
The layer needed a marker namespace the metabolic content had never used
(`TIGRFAM`), a GIFT mode the schema declared but nothing had exercised
(`interconversion`), and a reaction with no Rhea master — and all three were
already supported. `.infer_marker_namespace()` has recognised `^TIGR[0-9]{5}$`
since the evaluator was written, `marker.namespace` has never carried a `CHECK`,
and `rhea_master` became nullable for the polysaccharide layer. The one R change
this release does carry is the `interconversion` boundary contract, below, and
it came from writing that mode's meaning down rather than from the SCFA content.

**Tests.** A new `test-scfa.R` (98 assertions) covers the layer's biology: that
the chain-length-generic core markers do **not** complete `butyrate_formation`,
that neither `K01034`/`K01035` nor the butyrate kinase pair completes it, that
`TIGR03948` does; that adding the generic electron-transfer flavoprotein changes
no call; that the dehydrogenase complex has two E1 architectures and the
ferredoxin oxidoreductase two subunit architectures; that a two-of-three PduCDE
holoenzyme is incomplete; that the acrylate route reports its unannotated
reductase as a missing reaction rather than scoring it away; and that declaring
acetyl-CoA an anchor creates no edge from the biosynthesis GIFTs that consume it
internally.

**Three existing tests changed, and one of them mattered.**
`test-sugar-degradation.R` asserted that "a degradation GIFT is never upstream of
anything". That was an accident of coverage, not an invariant: nothing
downstream of pyruvate or lactaldehyde had been curated. It now asserts what the
test was actually protecting — that a degradation GIFT is never upstream of a
*biosynthesis* GIFT, and that its only outgoing edges run through the declared
anchors `PYRUVATE` and `LACTALDEHYDE`. The other two are roster and row-count
updates in `test-database.R` and `test-gift-types.R`; the latter became a
containment check so that the 29 pre-migration metabolic GIFTs are still
protected from changing type without freezing the set they belong to.

**Effect on users.** Six new callable GIFTs, and the composition graph now runs
from polysaccharide saccharification through sugar catabolism to a named
fermentation product. `gift_profile()` reports `cross_feeding_output` as 0 for
the whole layer and `resource_strategy` as `private`, which is deliberate: no
SCFA transporter marker licenses the extracellular anchor that cross-feeding
would need, so the model declines to claim it. No existing GIFT call changes.

### 2026-08-18T14:00Z — SCFA formation assessed, then curated

The assessment is `inst/doc/proposal-scfa-biosynthesis.md`; the content it
recommended is release 2026.13.1, described in the entry below. **No schema and
no R change** — this is a content release, and the proposal's first claim was
that it could be.

**Change.** Eight candidate short-chain fatty acid formation traits were tested
against the evidence available in KEGG, Rhea, ChEBI, MetaCyc and
InterPro/NCBIfam. Three are recommended for curation, one conditionally, and
four are refused. A prerequisite `pyruvate_to_acetyl_coa` GIFT is recommended
alongside them, because gifter's catabolic content currently ends at `PYRUVATE`
and the SCFA layer would otherwise be an island in `gift_graph`.

**Why it is worth reading before the next content release.** The layer needs no
schema migration and no R change, and it is the first candidate layer where the
*evidence* rather than the ontology is the binding constraint, in two ways the
existing proposals had not met:

- *KEGG orthology is insufficient for butyrate, measurably.* A KO-evidenced
  butyrate trait calls *Faecalibacterium prausnitzii*, *Roseburia intestinalis*
  and *Agathobacter rectalis* negative, and *Bacillus subtilis* positive; of 366
  KEGG organisms completing the core plus a terminal KO, 120 are *Bacillus*. The
  marker that does carry the claim is NCBIfam `TIGR03948` — which
  `.infer_marker_namespace()` already recognises and no curated row has ever
  used. The refusal is a marker-namespace gap, not an ontology gap, and the fix
  is the same one the collagenase `PFAM PF01752` row already took.
- *Fermentative end-product markers are direction-blind.* Every trait gifter
  carries today is directionally unambiguous. Pta–AckA runs both ways, and the
  methylmalonyl-CoA genes of the propionate succinate route are the same genes
  KEGG module M00741 uses to degrade propanoyl-CoA. The proposal adds a second
  clause to the specificity test for this, and recommends `mode =
  'interconversion'` — the schema's fourth mode value, so far unused — for the
  acetate node.

**Effect.** None on behaviour. The document records four refusals with their
evidence and their trigger conditions, so that the next reader who finds `buk`
missing from the database learns why rather than adding it.

### 2026-08-18T12:00Z — Regulatory and defense models gain curated content

**Change.** Five GIFTs are curated, filling the two typed models that shipped
with schema only: `chemotaxis_signal_transduction`, `aspartate_chemoreception`
and `phosphate_starvation_response` (regulatory), and
`type_i_restriction_modification` and `type_i_e_crispr_cas_machinery`
(defense). Database version moves to 2026.12.3. **The schema is unchanged at
version 6** — this is a content release, which is the point: adding a
capability of an existing type is a data change plus tests, not an R branch.

**Code.** One line: `.gifter_required_gift_facets` now requires
`regulatory_class` of regulatory GIFTs and `defense_class` of defense ones, and
`facet_terms.tsv` registers the four values those two vocabularies use. Each
vocabulary was registered when the first content of its type was curated, not
ahead of it. No evaluator, validator or accessor change was needed.

**Why these five.** They were the sequence the type proposals recommended, and
each was blocked on a question that was then answered by measurement rather than
assumption:

- *Chemotaxis* needed no evidence the marker model lacks, and immediately
  exercises the specificity invariant. Requiring the generic chemoreceptor
  accession K03406 would have called *Escherichia coli* K-12 receptor-less — it
  carries none, its four receptors being assigned to characterised groups —
  while *Vibrio cholerae* carries 34. The reception function therefore accepts a
  generic *or* a characterised chemoreceptor.
- *Phosphate response* was blocked on whether orthology distinguishes a cognate
  PhoR/PhoB pair from a genome full of paralogous kinases and regulators. Gene
  counts across nine reference genomes showed the sensor single-copy where
  present and the two regulator groups mutually exclusive, with the *Bacillus*
  pair adjacent in the genome. That answer split one capability into two circuits
  sharing a sensor rather than one circuit that would have called *B. subtilis*
  negative.
- *Type I restriction-modification* was the cleanest multisubunit requirement
  available, and the KEGG groups are defined as type I subunits, so the type is
  part of the group definition rather than an inference from it.
- *Type I-E CRISPR-Cas* was curated under the narrowed claim its proposal
  recommended: encoded machinery, not interference, because an array is a
  structural feature no protein accession evidences.

**Refusals recorded with the content**, each enforced by a test:

- ligand-specific chemoreception beyond aspartate, because K05876 covers ribose
  and galactose in one group and K03406 covers everything;
- K07660, which shares the gene name *phoP* with the phosphate regulator and is
  the magnesium-sensing PhoP/PhoQ regulator, a different protein with the
  opposite genome distribution;
- the target sequence a type I system recognises, because HsdS specificity comes
  from variable target recognition domains an orthology group does not resolve;
- K07475, the HD module of a split Cas3, as evidence of the complete
  nuclease-helicase;
- CheV as a substitute for CheW.

**Effect on other types: none.** The 29 metabolic GIFTs and the two structural
ones are unchanged; the no-regression test now strips every non-metabolic model
rather than only the structural one.

**Report.** The atlas renders regulatory circuits and defense mechanisms through
the same machinery view the structural type already used, and the GIFT type
grouping axis now separates four groups.

**A note on what did not happen.** The first structural and regulatory GIFTs are
now both curated, so `flagellar_apparatus` + `chemotaxis_signal_transduction`
could be fused into a `motility` trait. They are not, and the architecture guide
says why: a derived statement should read the primary calls rather than hide
which half of it a genome satisfies.

### 2026-08-18T10:00Z — GIFT becomes an umbrella concept with an explicit type

**Change.** A GIFT is redefined as a biologically meaningful capability whose
genomic support is evaluated through an explicit, curated and traceable
completeness model, and every GIFT now declares a core `gift_type`:
`metabolic`, `structural`, `regulatory` or `defense`. Schema version moves from
5 to 6.

`gift_type` is not a facet. A facet classifies a call; the type decides which
completeness model produces one, which source tables may attach to the GIFT, and
what a positive call is allowed to mean. That is a change to the relational
contract, hence a migration rather than a new column.

**Reason.** A genome encodes capabilities that are not chemistry. Modelling a
flagellum or a restriction-modification system as a directed route between
molecular anchors would have required inventing input and output molecules the
structure does not have, and the call would then rest on a boundary claim nobody
could defend. Each type states its own completeness contract instead.

**Effect on the metabolic model: none.** All 29 previously curated GIFTs became
`gift_type = metabolic` with no change to their anchors, routes, reactions,
systems, components, markers, calls, traces, graph edges or derived profile.
`test-gift-types.R` proves this by compiling a database with the structural
content removed and comparing every metabolic call and trace against the shipped
one.

**Structural model.** Implemented in full, with its own biologically named
tables: `gift_architecture`, `architecture_function`, `structural_function`,
`structural_system`, `structural_component`, `structural_component_marker`. A
structural GIFT is complete when any curated architecture has every required
structural function supported; an incomplete call names the closest architecture
and the functions missing from it, never a fraction of expected genes.
`required = 0` marks an accessory function.

**Regulatory and defense models.** Schema and evaluator implemented under
`gift_circuit`/`circuit_function`/`regulatory_*` and
`gift_mechanism`/`mechanism_function`/`defense_*`; both ship with no curated
content, and their Boolean semantics are fixed by synthetic fixtures in
`test-regulatory-defense.R`. The design questions that block curation —
cognate sensor/regulator pairing, and whether a CRISPR claim needs evidence
beyond protein markers — are written down in the type proposals rather than
answered by convenient curation.

The three non-metabolic models are kept as parallel table families rather than
merged into one generic set. Their Boolean shape is identical; a structural
function, a regulatory function and a defense function are not the same
biological object, and a source row is reviewable because of what it is called.
Only the operations whose semantics genuinely are identical are shared in code:
marker matching, component support, system AND logic, confidence ordering,
deterministic tie-breaking and result assembly. Whether the data model should
converge is left for after all three carry curated content.

**Public API.**

- `list_gifts()` gains a `type` argument and returns `gift_type`;
- `get_gift()` returns `gift_type`; `gifts_by_facet()` returns it too;
- `evaluate_gifts()` evaluates a mixed-type database in one call. Its `gifts`
  summary gains `gift_type` and a type-neutral answer — `best_implementation`,
  `number_of_complete_implementations`, `minimum_missing_requirements`,
  `missing_requirements`, `completeness_score` — beside the unchanged metabolic
  route columns, which are `NA` for non-metabolic GIFTs. New `structural`,
  `regulatory` and `defense` members carry the type-specific detail under
  biological names (`best_architecture`, `missing_functions_best_architecture`);
- `trace_gift()` dispatches on the type and gains an `implementation` argument
  for the machinery types; passing `route_id` for a non-metabolic GIFT, or
  `implementation` for a metabolic one, is an error rather than being ignored;
- `map_markers()` searches every model and gains `gift_type` and `function_id`.
  Component keys are unique only within a model, so they must be compared
  together with the type;
- new `get_gift_machinery()` returns the implementation, function, system,
  component and marker hierarchy of a non-metabolic GIFT;
- `gift_profile()` is documented and implemented as metabolic-only, because
  every field it derives comes from declared anchors.

**Validation.** Unknown or missing types are rejected. `mode`, anchors and
routes are refused on non-metabolic GIFTs and required on metabolic ones. An
implementation may not name a GIFT of another type. Required facets are scoped
by type, and a facet required of one type may not classify another. Function,
system, component and implementation identifiers must be unique across models,
because a trace prints them without naming their table. An implementation with
no required function is rejected. A separate fix makes the composition cycle
check skip a GIFT whose mode is missing rather than failing on an unnamed node.

**Report.** The atlas renders non-metabolic GIFTs as their alternative
implementations over the functions they share, with accessory functions dashed,
and offers GIFT type as a grouping axis. The new tables appear in the schema and
table browsers.

### 2026-08-19T00:30Z — Package renamed from distillR to giftr

The package is renamed to `giftr` and developed in its own repository. Every
identifier that carried the old name follows: `build_giftr_database()`,
`validate_giftr_sources()`, `write_giftr_database_html()`, `giftr_db_connect()`,
`giftr_db_disconnect()` and `giftr_db_version()`; the result classes
`giftr_result` and `giftr_reaction_result`; the packaged artefacts
`inst/extdata/giftr.sqlite`, `inst/extdata/giftr-database.html` and
`inst/schema/giftr.sql`; and the `database_release.giftr_db_version` column.

Calling this work distillR 2.0 implied continuity with a package built on a
different primitive — fullness scores over curated gene bundles. The
evaluation model, schema, public API and biological claims are all new and no
1.x code path survives, so a distinct name states plainly what the software is.
The package version starts afresh at 0.1.0. References to distillR that
describe the predecessor are kept as such in the architecture guide, the
curation proposals and the manuscript.

**Effect.** No change to evaluation logic, schema, or database content. The
database version is unaffected and remains 2026.12.1 at schema 5. Code written
against the unreleased distillR 2.0 development branch must rename the
identifiers above.

**Also.** `DESCRIPTION` gains `Config/build/clean-inst-doc: FALSE`. `inst/doc`
holds developer documentation rather than built vignettes, and the build tooling
clears that directory by default.

### 2026-08-18T23:59Z — Schema 5: facet classification and derived profile

**Change.** Schema version 5 replaces the free-text `gift.category` column with
a registered facet vocabulary, and adds a derived profile view.

`facet_term` registers every `(facet, value)` pair with the target it applies to
and a definition. `gift_facet` and `anchor_facet` carry the assignments; the
build rejects any pair that is not registered, any facet attached to the wrong
target, a GIFT without exactly one `substrate_class`, a GIFT without at least
one `physiological_role`, and an anchor without `molecular_tier` or
`biomass_essential`. `gift_route` gains a required `oxygen_requirement`, which
is a route property rather than a GIFT property because alternative routes to
the same anchors genuinely differ.

The `gift_profile` view derives `substrate_tier`, `resource_strategy`,
`network_position`, `cross_feeding_output` and `auxotrophy_indicator` from
declared anchors, anchor facets and the composition graph. Nothing in it is
curated. Facets and profile classify a call; neither enters the completeness
logic that produces one.

**API.** New: `list_facets()`, `get_facets()`, `gifts_by_facet()`,
`gift_profile()`. `list_gifts()`, `get_gift()` and `evaluate_gifts()` no longer
return `category`; `evaluate_gifts()` returns `substrate_class` instead.

**Effect.** No GIFT call changes. `resource_strategy` makes the
degrader-versus-forager distinction directly readable: `uptake`, `public_good`,
`private`, or `unresolved` where a compartment was never licensed.

**Migration note.** Consumers reading `category` should read `substrate_class`,
either from `evaluate_gifts()` or via `get_facets(gift_id)`.

### 2026-08-18T21:00Z — Polysaccharide content restructured; no code change

Database 2026.10.2 replaces six single-reaction polysaccharide GIFTs with three
substrate-level capabilities. The decision and its effect on calls are in
`database_changes.tsv`; this entry records only that a published shape was
retracted.

The first polysaccharide release made a GIFT equivalent to a reaction, which is
the marker-checklist shape the ontology exists to avoid, and left the
substrate-level question unanswerable by any single trait. `xylan_degradation`
now spans endo- and exo-acting chemistry with acetyl de-blocking as an accessory
reaction, and a genome carrying only one side reports an incomplete capability
naming the missing reaction.

**Migration note.** `xylan_depolymerisation`,
`xylooligosaccharide_saccharification`, `arabinoxylan_arabinofuranose_release`,
`starch_depolymerisation`, `starch_debranching` and
`maltooligosaccharide_saccharification` no longer exist. Use
`xylan_degradation`, `arabinoxylan_debranching` and `starch_degradation`. The
`XYLOOLIGOSACCHARIDE` and `MALTOOLIGOSACCHARIDE` anchors are withdrawn.

### 2026-08-18T18:00Z — Confidence follows the Boolean structure

**Change.** `evidence_confidence` is now computed as the *best* confidence among
the alternative markers supporting each component, then the *weakest* across the
components a route requires. It previously took the weakest across all
supporting markers.

**Why.** Alternative markers for one component are OR. Under the old rule,
adding a weak marker alongside a strong one made the call look worse — a genome
annotated with both the polyspecific CAZy family GH5 and the specific orthologue
K01181 reported `ambiguous`, when the specific evidence was present and
sufficient. Components are AND, so the weakest-wins rule is correct there and is
retained.

**Effect.** Confidence can only improve or stay equal for a given genome. No
Boolean call changes. Newly visible on database 2026.10.1, which is the first
content mixing curated orthology with polyspecific sequence families.

**Migration note.** Reaction identity is `reaction_id`, and `rhea_master` is now
`NA` for the polymer-acting reactions. Code filtering results with
`reactions$rhea_master == x` will return `NA` rows; filter on `reaction_id`.

### 2026-08-18T14:00Z — `mode` reaches the evaluation result

**Change.** The `gifts` tibble returned by `evaluate_gifts()` now carries
`mode`, matching `list_gifts()` and `get_gift()`. Filtering a result down to
transport or catabolic traits previously required a second lookup.

**Effect.** Additive; no call changes. Database 2026.09.4 adds the first two
transport GIFTs and the first compartment-split anchors, so the column now
distinguishes rows that were all `anabolic` before.

### 2026-08-18T10:00Z — Sugar degradation content; no code change

Database 2026.09.3 adds nine catabolic GIFTs. This entry is a pointer only: the
biological decisions, their evidence and their effect on calls are recorded in
`database_changes.tsv` and readable with `database_changelog()`. No package
behaviour changed, and no existing GIFT call changed.

The content exercises schema 4 for the first time: `mode = catabolic` on all
nine, and `reaction_id` carrying identity for 29 new reactions. Compartment
remains `unspecified` throughout, because no uptake GIFT is curated yet and the
splitting licence requires substrate-specific transporter evidence first.

### 2026-08-17T21:30Z — Schema 4: reaction identity, compartment, and GIFT mode

Infrastructure for the polysaccharide and sugar degradation layer described in
`inst/doc/proposal-polysaccharide-degradation.md`. No biological content is
added here and no existing GIFT call changes.

**Change.** Schema version 4 makes four structural changes.

*Reaction identity.* `reaction` gains a stable `reaction_id`, and `rhea_master`
becomes optional. `reactions.tsv` gains a `reaction_id` column, and
`route_reactions.tsv`, `enzyme_systems.tsv` and `reaction_xrefs.tsv` reference
it in place of `rhea_master`. For all content curated so far `reaction_id`
equals the Rhea master, so no reference changed value. A reaction curated
without a Rhea master must carry at least one `reaction_xrefs` entry.

*Anchor compartment.* `anchor` gains `molecule`, a stable key shared by the
compartment variants of one substance, and `compartment`, one of
`extracellular`, `cytoplasmic`, `unspecified`. `UNIQUE (molecule, compartment)`
becomes the natural key and `chebi_id` is no longer unique, because two location
states of one molecule carry the same ChEBI identifier. Every existing anchor is
`unspecified` with `molecule` equal to its `anchor_id`.

*GIFT mode.* `gift` gains `mode`, one of `anabolic`, `catabolic`, `transport`,
`interconversion`. The composition cycle check now runs per mode: a cycle within
one mode is still an error, a cycle between modes is not. All existing content
is `anabolic`.

*Graph edge quality.* The `gift_graph` view matches on `molecule` and reports
`edge_quality`. An edge is `exact` when both GIFTs declare the same anchor, and
`compartment_inexact` when they declare the same molecule and exactly one side
is `unspecified`. Two anchors whose compartments are both specified and
different are not connected, so a transport GIFT is required to cross that
boundary. `gift_graph()` gains a `quality` filter and returns `to_anchor`,
`shared_molecule` and `edge_quality` alongside the existing columns.

**Validation.** New errors: an invalid mode or compartment, a repeated
molecule/compartment pair, an empty `molecule`, a transport GIFT whose anchors
do not translocate one molecule, a malformed or duplicated Rhea master, and a
reaction with neither a Rhea master nor a cross-reference. New warning: a GIFT
that translocates a molecule without declaring `mode = transport`.

**Evaluation.** `evaluate_gifts()` reports `evidence_confidence` per GIFT — the
weakest qualitative confidence among the markers supporting the best route, so a
call resting on ambiguous evidence is distinguishable from one resting on
curated orthology. `trace_gift()` gains `reaction_id`. Route
`supporting_reactions` and `missing_reactions` now carry `reaction_id`, which is
never null.

**Markers.** CAZy accessions are recognised without an explicit namespace
(`GH5`, `GH5_4`, `PL1`, `CE8`, `AA9`, `CBM6`). A subfamily is a distinct
accession and never implies its parent family.

**API.** `get_reaction()` and `get_reaction_systems()` take `reaction`, matching
either a `reaction_id` or a Rhea master; `get_reaction(15753)` still resolves.
`list_gifts()` and `get_gift()` return `mode`; `get_gift_anchors()` returns
`molecule` and `compartment`; `get_gift_reactions()` returns `reaction_id`.

**Reason.** Rhea does not cover polymer-acting chemistry, catabolism and
biosynthesis legitimately close loops through shared metabolites, and the
degrader/forager/cross-feeder distinction is invisible without compartment.
Each was a blocker for curating carbohydrate degradation honestly.

**Effect.** No change to any existing GIFT call; 531 tests pass. Compartment
remains a curated boundary claim rather than a genomic inference — the scope
statements in `AGENTS.md` and `inst/doc/architecture.md` were amended to say so
and to enumerate what stays out of scope.

### 2026-08-17T20:10Z — GIFTs can be linked to related external pathways

**Change.** Schema version 3 adds the `gift_xref` table, compiled from the new
source `gift_xrefs.tsv`. Two accessors read it: `get_gift_pathways(gift_id,
namespace = NULL)` lists the external pathways related to a GIFT, and
`gifts_for_pathway(accession, namespace = NULL)` resolves a pathway identifier
back to the GIFTs that relate to it. Every reference carries a `relation` from
the closed vocabulary `equivalent`, `subset_of`, `superset_of`, `overlaps`,
`related`. Source validation rejects an unknown relation, a link to an unknown
GIFT, a duplicate GIFT/namespace/accession triple, and an empty namespace,
accession or name. The HTML atlas gains a `Related pathways` section on every
GIFT, with the relation spelled out in words, and pathway accessions are
searchable from the GIFT explorer.

**Why.** Users arrive from the resource they already know, but a GIFT is a
curated capability between declared anchors and is usually not the same object
as a pathway record. A bare cross-reference would imply an equivalence that is
false for most GIFTs — gifter splits KEGG M00018 across three traits and
merges M00338 with part of M00609. Storing the set relation makes the link
useful without weakening the claim. The namespace is deliberately open so that
resources beyond KEGG can be linked without a schema change.

**Effect.** No GIFT call changes. `gifter_db_version()` reports schema
version 3. Consumers reading `gift_xref` should treat `namespace` as an open
vocabulary and `relation` as closed.

---

### 2026-08-17T18:05Z — Curation history stored in the database and published in the atlas

**Change.** Schema version 2 adds the `database_change` and `change_gift`
tables, compiled from `database_changes.tsv` and `change_gifts.tsv`. New
accessor `database_changelog(gift_id = NULL)` returns the history, newest
first, with the affected GIFTs as a list column. The HTML atlas gains a
`Changelog` view rendering the history as a table — release, UTC timestamp,
hierarchy layer, category, effect on calls, the decision with its rationale,
evidence and effect, and the GIFT identifiers it affects. Selecting a GIFT
identifier opens that trait in the GIFT explorer, and every GIFT detail now
carries its own change history.

**Why.** Biological decisions were recorded in a Markdown file next to the
code, where they were invisible to anyone holding only the compiled database,
unlinked from the traits they changed, and mixed in with code history.

**Design decisions.** The history is curated source data, not documentation, so
it passes the same validation as the rest of the database: controlled
vocabularies for layer, category and effect on calls; ISO 8601 UTC timestamps;
and a foreign key from every entry to the GIFTs it affects. Validation requires
that link for changes to biological layers, and allows provenance and schema
entries to stand alone. `call_effect` is a first-class field rather than prose
because whether a change broadens or narrows calls is the question a user
re-running an analysis actually has.

**Effect.** No change to evaluation. Schema version 1 to 2; database release
2026.08.2 to 2026.08.3.

### 2026-08-17T16:49Z — Network visualisations in the database atlas

**Change.** `write_gifter_database_html()` now renders three inline SVG
network views: the existing directed GIFT composition graph, a new network
drawing GIFTs together with their declared anchors, and a merged route network
for every GIFT. A shared layered-graph engine in `R/database-visualization.R`
backs all three; the composition graph was moved onto it without changing its
appearance.

**Why.** The atlas described the evaluation hierarchy in tables and nested
disclosure but never showed the two structures that curation decisions actually
turn on: where alternative routes diverge and reconverge inside one GIFT, and
which anchors are the boundaries where GIFTs meet.

**Design decisions.** Route networks merge alternative routes onto shared
reaction nodes, so a parallel branch is a genuine route alternative and edge
thickness reports how many routes traverse a step. Anchors are drawn once in
the anchor network, so an anchor with both an incoming and an outgoing edge is
exactly the boundary where two GIFTs compose. Both networks are built strictly
from `gift_anchor` and `route_reaction`; no node exists that is not a declared
anchor or a curated route reaction, so a drawing can never imply a boundary
that curation did not declare. Graphs render at natural size and scroll
horizontally rather than being scaled down, which keeps long routes legible.

**Effect.** No change to evaluation or to the database. Tests assert the node
accounting of both networks, the route overlay counts, and marker-ID
uniqueness across the report.
