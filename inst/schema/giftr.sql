PRAGMA foreign_keys = ON;

-- A GIFT is a biologically meaningful capability whose genomic support is
-- evaluated through an explicit, curated and traceable completeness model.
--
-- `gift_type` is not a facet. A facet classifies a call; `gift_type` decides
-- which completeness model produces one, which tables may attach to the GIFT,
-- and what a positive call is allowed to mean. It is therefore part of the core
-- ontology and part of the relational contract.
CREATE TABLE gift (
  gift_pk INTEGER PRIMARY KEY,
  gift_id TEXT NOT NULL UNIQUE,
  gift_type TEXT NOT NULL CHECK (gift_type IN (
    'metabolic', 'structural', 'regulatory', 'defense'
  )),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  -- Direction of a metabolic capability, and meaningless for the other types:
  -- a flagellum has no anabolic or catabolic direction. Cycles in
  -- anchor-derived composition are forbidden within a mode and expected between
  -- modes, because a catabolic route back to a metabolite that an anabolic GIFT
  -- produces is real biology, not a boundary error.
  mode TEXT CHECK (mode IS NULL OR mode IN (
    'anabolic', 'catabolic', 'transport', 'interconversion'
  )),
  status TEXT NOT NULL,
  version TEXT NOT NULL,
  notes TEXT
);

-- Declared boundary molecule. `molecule` is the stable identity shared by the
-- compartment variants of one substance; `compartment` is a two-state location
-- qualifier used only to make transport and extracellular chemistry explicit.
-- giftr models no other aspect of cellular compartmentation: no membrane
-- potential, no transport stoichiometry, no compartment-aware mass balance and
-- no intracellular metabolite inventory.
CREATE TABLE anchor (
  anchor_pk INTEGER PRIMARY KEY,
  anchor_id TEXT NOT NULL UNIQUE,
  molecule TEXT NOT NULL,
  compartment TEXT NOT NULL DEFAULT 'unspecified' CHECK (compartment IN (
    'extracellular', 'cytoplasmic', 'unspecified'
  )),
  name TEXT NOT NULL,
  chebi_id TEXT,
  description TEXT,
  UNIQUE (molecule, compartment)
);

CREATE TABLE gift_anchor (
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  anchor_pk INTEGER NOT NULL REFERENCES anchor(anchor_pk),
  role TEXT NOT NULL CHECK (role IN ('input', 'output')),
  ordinal INTEGER NOT NULL CHECK (ordinal > 0),
  PRIMARY KEY (gift_pk, role, ordinal),
  UNIQUE (gift_pk, anchor_pk, role)
);

-- Related external pathways. A GIFT is never equal to a pathway record, so the
-- relation states how the curated boundaries compare with the external one.
-- The namespace is open so that resources other than KEGG can be linked.
CREATE TABLE gift_xref (
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  namespace TEXT NOT NULL,
  accession TEXT NOT NULL,
  name TEXT NOT NULL,
  relation TEXT NOT NULL CHECK (relation IN (
    'equivalent', 'subset_of', 'superset_of', 'overlaps', 'related'
  )),
  notes TEXT,
  PRIMARY KEY (gift_pk, namespace, accession)
);

-- Registered facet vocabulary. Open to new facets, closed within a facet: the
-- build rejects a (facet, value) pair not defined here, which is what keeps a
-- multi-valued classification from degenerating into free text. Facets classify
-- a call; they never enter the completeness logic that produces one.
CREATE TABLE facet_term (
  facet TEXT NOT NULL,
  value TEXT NOT NULL,
  applies_to TEXT NOT NULL CHECK (applies_to IN ('gift', 'anchor')),
  definition TEXT NOT NULL,
  PRIMARY KEY (facet, value)
);

-- Curated classification of a GIFT. Multi-valued in general. Which facets are
-- required is scoped by `gift.gift_type`: a metabolic GIFT needs exactly one
-- `substrate_class` and at least one `physiological_role`, a structural GIFT
-- needs exactly one `structural_class`, and a facet required of one type may
-- not classify another.
CREATE TABLE gift_facet (
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  facet TEXT NOT NULL,
  value TEXT NOT NULL,
  notes TEXT,
  PRIMARY KEY (gift_pk, facet, value),
  FOREIGN KEY (facet, value) REFERENCES facet_term(facet, value)
);

-- Curated classification of a boundary molecule. Provenance belongs here rather
-- than on the GIFT: arabinoxylan is plant-derived wherever it appears, and
-- asserting it once per anchor keeps the GIFTs that consume it from disagreeing.
-- `resource_origin` is deliberately multi-valued -- glucose is both diet- and
-- host-derived -- so filters on it return supersets, never partitions.
CREATE TABLE anchor_facet (
  anchor_pk INTEGER NOT NULL REFERENCES anchor(anchor_pk),
  facet TEXT NOT NULL,
  value TEXT NOT NULL,
  notes TEXT,
  PRIMARY KEY (anchor_pk, facet, value),
  FOREIGN KEY (facet, value) REFERENCES facet_term(facet, value)
);

-- Chemistry identity. A Rhea master ID is preferred and is used as the stable
-- `reaction_id` wherever one exists. Polymer-acting chemistry frequently has no
-- Rhea master, because a polysaccharide is a substrate class rather than a
-- compound with a balanced equation, so `rhea_master` is optional and such a
-- reaction must instead carry at least one cross-reference.
CREATE TABLE reaction (
  reaction_pk INTEGER PRIMARY KEY,
  reaction_id TEXT NOT NULL UNIQUE,
  rhea_master TEXT UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE reaction_xref (
  reaction_pk INTEGER NOT NULL REFERENCES reaction(reaction_pk),
  namespace TEXT NOT NULL,
  accession TEXT NOT NULL,
  PRIMARY KEY (reaction_pk, namespace, accession)
);

-- Alternative minimal route. `oxygen_requirement` is a route property, not a
-- GIFT property: alternative routes to the same anchors genuinely differ, and
-- recording it on the GIFT would flatten the distinction the OR-over-routes
-- model exists to preserve. `independent` means the chemistry needs neither the
-- presence nor the absence of oxygen, and is the correct answer for most
-- curated routes.
CREATE TABLE gift_route (
  route_pk INTEGER PRIMARY KEY,
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  route_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL,
  oxygen_requirement TEXT NOT NULL CHECK (oxygen_requirement IN (
    'aerobic', 'anaerobic', 'independent'
  ))
);

CREATE TABLE route_reaction (
  route_pk INTEGER NOT NULL REFERENCES gift_route(route_pk),
  reaction_pk INTEGER NOT NULL REFERENCES reaction(reaction_pk),
  orientation TEXT NOT NULL CHECK (orientation IN ('forward', 'reverse')),
  step_order INTEGER NOT NULL CHECK (step_order > 0),
  required INTEGER NOT NULL DEFAULT 1 CHECK (required IN (0, 1)),
  PRIMARY KEY (route_pk, reaction_pk),
  UNIQUE (route_pk, step_order)
);

CREATE TABLE enzyme_system (
  system_pk INTEGER PRIMARY KEY,
  reaction_pk INTEGER NOT NULL REFERENCES reaction(reaction_pk),
  system_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE enzyme_component (
  component_pk INTEGER PRIMARY KEY,
  system_pk INTEGER NOT NULL REFERENCES enzyme_system(system_pk),
  component_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE marker (
  marker_pk INTEGER PRIMARY KEY,
  namespace TEXT NOT NULL,
  accession TEXT NOT NULL,
  name TEXT,
  description TEXT,
  UNIQUE (namespace, accession)
);

CREATE TABLE component_marker (
  component_pk INTEGER NOT NULL REFERENCES enzyme_component(component_pk),
  marker_pk INTEGER NOT NULL REFERENCES marker(marker_pk),
  evidence_type TEXT NOT NULL,
  confidence TEXT NOT NULL,
  source TEXT NOT NULL,
  notes TEXT,
  PRIMARY KEY (component_pk, marker_pk)
);

-- ---------------------------------------------------------------------------
-- Typed non-metabolic GIFT models
--
-- A metabolic GIFT is a claim about chemistry, so its unit of completeness is a
-- reaction with an identity of its own (a Rhea master) and a direction within a
-- route. The other GIFT types make claims about encoded machinery, so their
-- unit of completeness is a named function fulfilled by protein systems.
--
-- The three families below are deliberately kept separate rather than merged
-- into one generic table set. Their Boolean shape is the same, but a structural
-- function, a regulatory function and a defense function are different
-- biological objects, and the names are what make a curated row reviewable.
-- Whether any of them should later share a representation is a question for
-- after real curated content exists in all three.
-- ---------------------------------------------------------------------------

-- A discrete structural or assembly function that an architecture requires,
-- such as building the hook or generating torque. It is the structural
-- analogue of a reaction: the unit whose absence is reported when a
-- structural GIFT is incomplete. Functions are reusable, so two architectures
-- of the same apparatus share them rather than duplicating their systems.
CREATE TABLE structural_function (
  function_pk INTEGER PRIMARY KEY,
  function_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

-- One alternative implementation of a structural function. Systems are
-- alternatives under OR; a system's components are jointly required.
CREATE TABLE structural_system (
  system_pk INTEGER PRIMARY KEY,
  function_pk INTEGER NOT NULL REFERENCES structural_function(function_pk),
  system_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE structural_component (
  component_pk INTEGER PRIMARY KEY,
  system_pk INTEGER NOT NULL REFERENCES structural_system(system_pk),
  component_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE structural_component_marker (
  component_pk INTEGER NOT NULL REFERENCES structural_component(component_pk),
  marker_pk INTEGER NOT NULL REFERENCES marker(marker_pk),
  evidence_type TEXT NOT NULL,
  confidence TEXT NOT NULL,
  source TEXT NOT NULL,
  notes TEXT,
  PRIMARY KEY (component_pk, marker_pk)
);

-- One complete curated architecture of a cellular structure or molecular
-- machine. Architectures are alternatives under OR: the diderm flagellum and
-- the monoderm flagellum are different architectures of the same apparatus,
-- not one architecture with an optional part.
CREATE TABLE gift_architecture (
  architecture_pk INTEGER PRIMARY KEY,
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  architecture_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL
);

-- AND membership. `required = 0` marks an accessory function whose absence does
-- not make the architecture incomplete; `ordinal` orders the report only.
CREATE TABLE architecture_function (
  architecture_pk INTEGER NOT NULL REFERENCES gift_architecture(architecture_pk),
  function_pk INTEGER NOT NULL REFERENCES structural_function(function_pk),
  ordinal INTEGER NOT NULL CHECK (ordinal > 0),
  required INTEGER NOT NULL DEFAULT 1 CHECK (required IN (0, 1)),
  PRIMARY KEY (architecture_pk, function_pk),
  UNIQUE (architecture_pk, ordinal)
);

-- A discrete information-transduction function a circuit requires, such as
-- sensing a defined signal or effecting a defined transcriptional response.
CREATE TABLE regulatory_function (
  function_pk INTEGER PRIMARY KEY,
  function_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

-- One alternative implementation of a regulatory function. Marker accession
-- alone may not always be sufficient evidence for a regulatory system; see
-- inst/doc/proposal-regulatory-gifts.md for the open evidence question.
CREATE TABLE regulatory_system (
  system_pk INTEGER PRIMARY KEY,
  function_pk INTEGER NOT NULL REFERENCES regulatory_function(function_pk),
  system_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE regulatory_component (
  component_pk INTEGER PRIMARY KEY,
  system_pk INTEGER NOT NULL REFERENCES regulatory_system(system_pk),
  component_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE regulatory_component_marker (
  component_pk INTEGER NOT NULL REFERENCES regulatory_component(component_pk),
  marker_pk INTEGER NOT NULL REFERENCES marker(marker_pk),
  evidence_type TEXT NOT NULL,
  confidence TEXT NOT NULL,
  source TEXT NOT NULL,
  notes TEXT,
  PRIMARY KEY (component_pk, marker_pk)
);

-- One complete curated circuit that detects a defined signal and executes a
-- defined regulatory response. Circuits are alternatives under OR.
CREATE TABLE gift_circuit (
  circuit_pk INTEGER PRIMARY KEY,
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  circuit_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL
);

-- AND membership. `required = 0` marks an accessory function whose absence does
-- not make the circuit incomplete; `ordinal` orders the report only.
CREATE TABLE circuit_function (
  circuit_pk INTEGER NOT NULL REFERENCES gift_circuit(circuit_pk),
  function_pk INTEGER NOT NULL REFERENCES regulatory_function(function_pk),
  ordinal INTEGER NOT NULL CHECK (ordinal > 0),
  required INTEGER NOT NULL DEFAULT 1 CHECK (required IN (0, 1)),
  PRIMARY KEY (circuit_pk, function_pk),
  UNIQUE (circuit_pk, ordinal)
);

-- A discrete defensive function a mechanism requires, such as recognising a
-- target sequence, cleaving invading DNA, or protecting self DNA.
CREATE TABLE defense_function (
  function_pk INTEGER PRIMARY KEY,
  function_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

-- One alternative implementation of a defense function. Protein markers may
-- not be sufficient evidence for every defense system; see
-- inst/doc/proposal-defense-gifts.md.
CREATE TABLE defense_system (
  system_pk INTEGER PRIMARY KEY,
  function_pk INTEGER NOT NULL REFERENCES defense_function(function_pk),
  system_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE defense_component (
  component_pk INTEGER PRIMARY KEY,
  system_pk INTEGER NOT NULL REFERENCES defense_system(system_pk),
  component_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE defense_component_marker (
  component_pk INTEGER NOT NULL REFERENCES defense_component(component_pk),
  marker_pk INTEGER NOT NULL REFERENCES marker(marker_pk),
  evidence_type TEXT NOT NULL,
  confidence TEXT NOT NULL,
  source TEXT NOT NULL,
  notes TEXT,
  PRIMARY KEY (component_pk, marker_pk)
);

-- One complete curated defense mechanism against a defined biological or
-- chemical challenge. Mechanisms are alternatives under OR.
CREATE TABLE gift_mechanism (
  mechanism_pk INTEGER PRIMARY KEY,
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  mechanism_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL
);

-- AND membership. `required = 0` marks an accessory function whose absence does
-- not make the mechanism incomplete; `ordinal` orders the report only.
CREATE TABLE mechanism_function (
  mechanism_pk INTEGER NOT NULL REFERENCES gift_mechanism(mechanism_pk),
  function_pk INTEGER NOT NULL REFERENCES defense_function(function_pk),
  ordinal INTEGER NOT NULL CHECK (ordinal > 0),
  required INTEGER NOT NULL DEFAULT 1 CHECK (required IN (0, 1)),
  PRIMARY KEY (mechanism_pk, function_pk),
  UNIQUE (mechanism_pk, ordinal)
);

CREATE TABLE database_release (
  release_pk INTEGER PRIMARY KEY CHECK (release_pk = 1),
  giftr_db_version TEXT NOT NULL,
  schema_version INTEGER NOT NULL,
  build_date TEXT NOT NULL,
  rhea_release TEXT NOT NULL,
  chebi_release TEXT NOT NULL,
  kegg_release TEXT NOT NULL,
  source_commit TEXT NOT NULL
);

-- Curation history of the biological database. Code and API changes are not
-- recorded here; they belong to the package changelog.
CREATE TABLE database_change (
  change_pk INTEGER PRIMARY KEY,
  change_id TEXT NOT NULL UNIQUE,
  released TEXT NOT NULL,
  changed_at TEXT NOT NULL,
  layer TEXT NOT NULL CHECK (layer IN (
    'gift', 'anchor', 'route', 'reaction', 'enzyme_system',
    'enzyme_component', 'marker',
    'architecture', 'structural_function', 'structural_system', 'structural_component',
    'circuit', 'regulatory_function', 'regulatory_system', 'regulatory_component',
    'mechanism', 'defense_function', 'defense_system', 'defense_component',
    'provenance', 'schema'
  )),
  category TEXT NOT NULL CHECK (category IN (
    'addition', 'correction', 'removal', 'clarification'
  )),
  call_effect TEXT NOT NULL CHECK (call_effect IN ('broadens', 'narrows', 'mixed', 'none')),
  summary TEXT NOT NULL,
  rationale TEXT NOT NULL,
  evidence TEXT,
  effect TEXT
);

CREATE TABLE change_gift (
  change_pk INTEGER NOT NULL REFERENCES database_change(change_pk),
  gift_pk INTEGER NOT NULL REFERENCES gift(gift_pk),
  PRIMARY KEY (change_pk, gift_pk)
);

CREATE INDEX idx_gift_gift_id ON gift(gift_id);
CREATE INDEX idx_gift_gift_type ON gift(gift_type);
CREATE INDEX idx_anchor_anchor_id ON anchor(anchor_id);
CREATE INDEX idx_anchor_chebi_id ON anchor(chebi_id);
CREATE INDEX idx_anchor_molecule ON anchor(molecule);
CREATE INDEX idx_reaction_reaction_id ON reaction(reaction_id);
CREATE INDEX idx_reaction_rhea_master ON reaction(rhea_master);
CREATE INDEX idx_marker_namespace_accession ON marker(namespace, accession);
CREATE INDEX idx_gift_route_gift_pk ON gift_route(gift_pk);
CREATE INDEX idx_route_reaction_route_pk ON route_reaction(route_pk);
CREATE INDEX idx_route_reaction_reaction_pk ON route_reaction(reaction_pk);
CREATE INDEX idx_enzyme_system_reaction_pk ON enzyme_system(reaction_pk);
CREATE INDEX idx_enzyme_component_system_pk ON enzyme_component(system_pk);
CREATE INDEX idx_component_marker_marker_pk ON component_marker(marker_pk);
CREATE INDEX idx_gift_xref_gift_pk ON gift_xref(gift_pk);
CREATE INDEX idx_gift_xref_accession ON gift_xref(namespace, accession);
CREATE INDEX idx_database_change_change_id ON database_change(change_id);
CREATE INDEX idx_change_gift_gift_pk ON change_gift(gift_pk);
CREATE INDEX idx_gift_facet_gift_pk ON gift_facet(gift_pk);
CREATE INDEX idx_gift_facet_lookup ON gift_facet(facet, value);
CREATE INDEX idx_anchor_facet_anchor_pk ON anchor_facet(anchor_pk);
CREATE INDEX idx_anchor_facet_lookup ON anchor_facet(facet, value);

CREATE INDEX idx_structural_system_function_pk ON structural_system(function_pk);
CREATE INDEX idx_structural_component_system_pk ON structural_component(system_pk);
CREATE INDEX idx_structural_component_marker_marker_pk ON structural_component_marker(marker_pk);
CREATE INDEX idx_gift_architecture_gift_pk ON gift_architecture(gift_pk);
CREATE INDEX idx_architecture_function_function_pk ON architecture_function(function_pk);
CREATE INDEX idx_regulatory_system_function_pk ON regulatory_system(function_pk);
CREATE INDEX idx_regulatory_component_system_pk ON regulatory_component(system_pk);
CREATE INDEX idx_regulatory_component_marker_marker_pk ON regulatory_component_marker(marker_pk);
CREATE INDEX idx_gift_circuit_gift_pk ON gift_circuit(gift_pk);
CREATE INDEX idx_circuit_function_function_pk ON circuit_function(function_pk);
CREATE INDEX idx_defense_system_function_pk ON defense_system(function_pk);
CREATE INDEX idx_defense_component_system_pk ON defense_component(system_pk);
CREATE INDEX idx_defense_component_marker_marker_pk ON defense_component_marker(marker_pk);
CREATE INDEX idx_gift_mechanism_gift_pk ON gift_mechanism(gift_pk);
CREATE INDEX idx_mechanism_function_function_pk ON mechanism_function(function_pk);

-- Composition edges derived from declared anchors only.
--
-- An edge is `exact` when both GIFTs declare the same anchor. It is
-- `compartment_inexact` when they declare the same molecule and exactly one
-- side leaves the compartment unresolved: that happens where transporter
-- evidence was insufficient to license a compartment split, and breaking the
-- chain there would turn a missing marker into a false negative for the whole
-- capability.
--
-- Two anchors whose compartments are both specified and different are NOT
-- connected. That is what keeps transport GIFTs load-bearing: extracellular
-- glucose must not reach cytoplasmic glucose except through an uptake GIFT.
CREATE VIEW gift_graph AS
SELECT DISTINCT
  upstream.gift_id AS from_gift,
  out_anchor.anchor_id AS shared_anchor,
  in_anchor.anchor_id AS to_anchor,
  out_anchor.molecule AS shared_molecule,
  CASE
    WHEN out_anchor.anchor_pk = in_anchor.anchor_pk THEN 'exact'
    ELSE 'compartment_inexact'
  END AS edge_quality,
  downstream.gift_id AS to_gift
FROM gift_anchor output_boundary
JOIN gift upstream ON upstream.gift_pk = output_boundary.gift_pk
JOIN anchor out_anchor ON out_anchor.anchor_pk = output_boundary.anchor_pk
JOIN gift_anchor input_boundary ON input_boundary.role = 'input'
JOIN anchor in_anchor ON in_anchor.anchor_pk = input_boundary.anchor_pk
JOIN gift downstream ON downstream.gift_pk = input_boundary.gift_pk
WHERE output_boundary.role = 'output'
  AND out_anchor.molecule = in_anchor.molecule
  AND (
    out_anchor.anchor_pk = in_anchor.anchor_pk
    OR out_anchor.compartment = 'unspecified'
    OR in_anchor.compartment = 'unspecified'
  )
  AND upstream.gift_pk <> downstream.gift_pk;

-- Derived ecological and physiological profile of a metabolic GIFT.
--
-- Nothing here is curated. Every field is computed from declared anchors, the
-- anchor facets, and the composition graph, which is why adding it required no
-- curation campaign: the signal was already in the database and simply had no
-- way out. Facets and profile classify a call; neither changes one.
--
-- `resource_strategy` is the degrader-versus-forager distinction the compartment
-- field exists to support. `unresolved` is a real answer, not a gap: a GIFT that
-- consumes an extracellular polymer and releases a product whose compartment was
-- never licensed genuinely does not say whether the product is shared.
CREATE VIEW gift_profile AS
WITH boundary AS (
  SELECT
    ga.gift_pk,
    MAX(ga.role = 'input'  AND a.compartment = 'extracellular') AS in_extracellular,
    MAX(ga.role = 'output' AND a.compartment = 'extracellular') AS out_extracellular,
    MAX(ga.role = 'output' AND a.compartment = 'cytoplasmic')   AS out_cytoplasmic
  FROM gift_anchor ga
  JOIN anchor a ON a.anchor_pk = ga.anchor_pk
  GROUP BY ga.gift_pk
),
tier AS (
  SELECT
    ga.gift_pk,
    MIN(CASE af.value
      WHEN 'polymer' THEN 1
      WHEN 'oligosaccharide' THEN 2
      WHEN 'monomer' THEN 3
      ELSE 4
    END) AS tier_rank
  FROM gift_anchor ga
  JOIN anchor_facet af
    ON af.anchor_pk = ga.anchor_pk AND af.facet = 'molecular_tier'
  WHERE ga.role = 'input'
  GROUP BY ga.gift_pk
),
crossfeed AS (
  SELECT DISTINCT released.gift_pk
  FROM gift_anchor released
  JOIN anchor a ON a.anchor_pk = released.anchor_pk
  JOIN gift_anchor consumed
    ON consumed.anchor_pk = released.anchor_pk
   AND consumed.role = 'input'
   AND consumed.gift_pk <> released.gift_pk
  WHERE released.role = 'output' AND a.compartment = 'extracellular'
),
auxotrophy AS (
  SELECT DISTINCT ga.gift_pk
  FROM gift_anchor ga
  JOIN gift g ON g.gift_pk = ga.gift_pk AND g.mode = 'anabolic'
  JOIN anchor_facet af
    ON af.anchor_pk = ga.anchor_pk
   AND af.facet = 'biomass_essential' AND af.value = 'yes'
  WHERE ga.role = 'output'
)
SELECT
  g.gift_id,
  g.mode,
  (SELECT value FROM gift_facet
    WHERE gift_pk = g.gift_pk AND facet = 'substrate_class') AS substrate_class,
  CASE tier.tier_rank
    WHEN 1 THEN 'polymer'
    WHEN 2 THEN 'oligosaccharide'
    WHEN 3 THEN 'monomer'
    ELSE 'small_molecule'
  END AS substrate_tier,
  CASE
    WHEN boundary.in_extracellular = 1 AND boundary.out_cytoplasmic = 1 THEN 'uptake'
    WHEN boundary.in_extracellular = 1 AND boundary.out_extracellular = 1 THEN 'public_good'
    WHEN boundary.in_extracellular = 0 AND boundary.out_extracellular = 0 THEN 'private'
    ELSE 'unresolved'
  END AS resource_strategy,
  CASE
    WHEN incoming.n > 0 AND outgoing.n > 0 THEN 'intermediate'
    WHEN outgoing.n > 0 THEN 'entry'
    WHEN incoming.n > 0 THEN 'terminal'
    ELSE 'isolated'
  END AS network_position,
  CASE WHEN crossfeed.gift_pk IS NOT NULL THEN 1 ELSE 0 END AS cross_feeding_output,
  CASE WHEN auxotrophy.gift_pk IS NOT NULL THEN 1 ELSE 0 END AS auxotrophy_indicator
FROM gift g
LEFT JOIN boundary ON boundary.gift_pk = g.gift_pk
LEFT JOIN tier ON tier.gift_pk = g.gift_pk
LEFT JOIN crossfeed ON crossfeed.gift_pk = g.gift_pk
LEFT JOIN auxotrophy ON auxotrophy.gift_pk = g.gift_pk
LEFT JOIN (
  SELECT to_gift AS gift_id, COUNT(DISTINCT from_gift) AS n FROM gift_graph GROUP BY to_gift
) incoming ON incoming.gift_id = g.gift_id
LEFT JOIN (
  SELECT from_gift AS gift_id, COUNT(DISTINCT to_gift) AS n FROM gift_graph GROUP BY from_gift
) outgoing ON outgoing.gift_id = g.gift_id
-- The profile is derived entirely from declared anchors and the anchor-derived
-- composition graph, which only metabolic GIFTs have. Reporting an empty
-- profile row for a structural GIFT would invent a resource strategy it does
-- not have.
WHERE g.gift_type = 'metabolic';
