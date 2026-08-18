# Regulatory GIFTs: curated content, refusals, and open questions

Status: **partly implemented**. `chemotaxis_signal_transduction`,
`aspartate_chemoreception` and `phosphate_starvation_response` are curated.
The evidence-model limitation below is unchanged and still bounds what a
regulatory GIFT may claim. Boolean semantics are fixed by synthetic fixtures and
by the curated content in `tests/testthat/test-regulatory-defense.R`.

A **regulatory GIFT** claims:

> the genome encodes the capability to detect or receive a biologically defined
> signal and execute a defined information-transduction response, through at
> least one complete curated circuit.

```text
REGULATORY GIFT
  |
  +-- OR --> CIRCUIT
                |
                +-- AND --> REGULATORY FUNCTION
                                 |
                                 +-- OR --> SYSTEM
                                                |
                                                +-- AND --> COMPONENT
                                                               |
                                                               +-- OR --> EVIDENCE
```

## The blocking question: is a marker accession sufficient evidence?

For metabolic and structural GIFTs it is. An enzyme component is a protein role,
and an orthologue accession is evidence that the genome encodes a protein in
that role. Regulatory systems strain this in a way the other types do not,
because what makes a two-component system *that* system is often not the
identity of its proteins but their **pairing**.

Four kinds of evidence that a curated regulatory claim may need, none of which
the current marker model can express:

1. **Cognate sensor/regulator pairing.** A genome may encode forty histidine
   kinases and forty response regulators. That it encodes one of each says
   nothing about whether any given pair is a functioning circuit.
2. **Gene neighbourhood.** Cognate two-component pairs are usually adjacent.
   Adjacency is genomic evidence, but it is a property of a gene *pair in a
   genome*, not an accession.
3. **Domain architecture.** A sensor's input domain is what determines what it
   senses. Two kinases in the same orthology group can carry different periplasmic
   sensing domains.
4. **Operon context.** Whether the regulated genes are present at all.

None of these fit `namespace + accession`, because none of them is a property of
a reference database entry: they are properties of the genome being evaluated.
Supporting them means extending the evidence layer from "does this genome
contain an annotation?" to "does this genome satisfy this predicate?", which is
a substantially larger change than adding a GIFT type — it changes what an
annotation table has to contain.

**The marker model has deliberately not been generalised.** The three curated
regulatory GIFTs do not need it, because the calibration below showed that the
orthology groups in question are single-copy and mutually exclusive rather than
absorbing paralogues. The extension remains the right answer for a future claim
that genuinely depends on pairing, neighbourhood or domain architecture, and
`AGENTS.md`'s rule about not broadening the model without a concrete case still
applies.

A curated regulatory GIFT must therefore stay within what an accession can
support: which proteins the genome encodes, not which of its many kinases pairs
with which of its many regulators.

## Curated: phosphate starvation response

### The claim

> The genome encodes a phosphate-starvation two-component regulatory system: the
> PhoR sensor histidine kinase paired with a cognate phosphate-regulon response
> regulator.

It does not claim that the regulon is induced, that the cell is phosphate
limited, or that any particular gene is regulated.

### The calibration that unblocked it

The blocking question was whether orthology alone distinguishes a cognate Pho
pair from a genome full of paralogous kinases and regulators. Gene counts per
genome, from the KEGG REST API on 2026-08-18:

| Organism | K07636 `phoR` | K07657 `phoB` | K07658 `phoP` |
|---|---|---|---|
| *Escherichia coli* K-12 | 1 | 1 | 0 |
| *Salmonella* Typhi | 1 | 1 | 0 |
| *Pseudomonas aeruginosa* | 1 | 1 | 0 |
| *Vibrio cholerae* | 1 | 1 | 0 |
| *Bacillus subtilis* | 1 | 0 | 1 |
| *Campylobacter jejuni* | 0 | 0 | 0 |
| *Helicobacter pylori* | 0 | 0 | 0 |
| *Mycobacterium tuberculosis* | 0 | 0 | 0 |
| *Lactococcus lactis* | 0 | 0 | 0 |

Three things follow. The sensor group is single-copy where present, so it is not
absorbing paralogous histidine kinases. The two regulator groups are mutually
exclusive across every genome checked. And in *B. subtilis* the K07658 regulator
(BSU29110) is immediately adjacent to the K07636 sensor (BSU29100) — the cognate
pair, recovered from orthology alone.

The residual limitation is stated rather than hidden: this is nine reference
genomes, not a genome-wide false-positive rate. It answers the specific worry
about paralogue absorption; it is not a calibration study.

### What the calibration changed about the design

It split one capability into **two circuits sharing a sensor**:

```text
phosphate_starvation_response
├── CIRCUIT_PHO_PHOR_PHOB    PhoR + PhoB    enterobacteria, pseudomonads, vibrios
└── CIRCUIT_PHO_PHOR_PHOP    PhoR + PhoP    Bacillus and relatives
```

A single PhoR/PhoB circuit would have called *B. subtilis* — a genuine
phosphate-starvation responder — negative. Requiring only PhoR would have
claimed a circuit from half a circuit.

### A name collision that had to be refused

`K07660` is also called *phoP*. It is the response regulator of the
magnesium-sensing PhoP/PhoQ system, present in *E. coli* and *Salmonella* and
absent from *B. subtilis* — the opposite distribution from K07658, and a
different protein. Accepting it would have called a phosphate response from a
genome that has none. It is refused, and the test
`the magnesium-sensing PhoP is not accepted as a phosphate regulator` keeps it
refused.

### What remains settled by choice rather than by evidence

- The functions decompose cleanly: **signal reception** (the PhoR sensor kinase,
  in the context of the PstSCAB–PhoU transporter complex that conveys phosphate
  status to it) and **transcriptional response** (the PhoB response regulator
  acting at Pho box promoters).
- KEGG carries orthologue-specific accessions — `K07636` for *phoR* and
  `K07657` for *phoB* — rather than generic histidine kinase and response
  regulator groups, so at first sight the pairing problem is solved by orthology.

- **PstSCAB–PhoU is accessory, not required.** The transporter is how PhoR
  learns the phosphate status, but it is independently a transport capability
  that the metabolic model already covers, and requiring it here would curate
  the same biology twice. A genome without it still encodes the signalling
  machinery, which is what the claim is about.
- **The claim is about the circuit, not the regulon.** A circuit with no Pho box
  genes to regulate is a machine with nothing to do, and giftr does not model
  regulons. This is a real limit on what the trait means, not an oversight.

## Curated: core chemotaxis signal transduction

### The claim

> The genome encodes the core chemotaxis signal-transduction machinery: a
> chemoreceptor, the CheA histidine kinase with its CheW coupling protein, the
> CheY response regulator, and the CheR/CheB adaptation cycle.

It does not claim that the cell is chemotactic, nor that it responds to any
particular compound.

### What the curation settled

- **Adaptation is required.** The CheR/CheB methylation cycle is what makes the
  system respond to gradients rather than to absolute concentrations; without it
  the pathway saturates. Both enzymes are components of one system, because a
  cycle that only adds methyl groups does not run.
- **Signal termination is accessory,** with three non-homologous systems: CheZ,
  CheC and CheX. CheY-P also autodephosphorylates, and the phosphatase families
  are distributed unevenly, so a genome without one still transduces a signal.
  This is the regulatory instance of non-homologous replacement.
- **CheV is not accepted as a CheW substitute.** It is a CheW-response regulator
  hybrid that occurs *alongside* CheW in the Firmicutes that have it, so it does
  not evidence the coupling function on its own.

### The receptor problem, measured rather than assumed

Requiring the generic chemoreceptor accession K03406 would have called
*Escherichia coli* K-12 — the organism the whole pathway was worked out in —
receptor-less. Gene counts from the KEGG REST API on 2026-08-18:

| Organism | K03406 generic MCP |
|---|---|
| *Escherichia coli* K-12 | **0** |
| *Salmonella* Typhi | 1 |
| *Bacillus subtilis* | 8 |
| *Pseudomonas aeruginosa* | 21 |
| *Vibrio cholerae* | 34 |

*E. coli*'s four receptors are assigned to characterised groups instead:
K05874 (Tsr, serine), K05875 (Tar, aspartate), K05876 (Trg, ribose/galactose)
and K03776 (Aer, redox). The reception function therefore has two alternative
systems — a generic chemoreceptor, or any characterised one — and either
satisfies it.

The same table is the evidence for the specificity refusal below: a genome with
34 chemoreceptors all assigned to one accession is a genome whose chemoeffectors
that accession cannot name.

## Curated: aspartate chemoreception, and the refusal behind it

### Why a second, narrower GIFT exists

The evidence-specificity invariant in a regulatory setting:

> A generic methyl-accepting chemotaxis protein marker must not license a
> ligand-specific claim such as "chemotaxis toward glucose".

A methyl-accepting chemotaxis protein accession identifies the *signalling*
architecture — the conserved cytoplasmic domain that talks to CheA — and says
nothing about the periplasmic ligand-binding domain that determines what the
receptor detects. A single genome may encode dozens of chemoreceptors with
entirely different specificities and identical signalling domains.

So there are two claims, and they are not the same claim. Rather than leave the
principle implicit, both are curated with strictly different evidence:

| GIFT | Reception evidence | Accepts K03406? |
|---|---|---|
| `chemotaxis_signal_transduction` | any chemoreceptor, generic or characterised | yes |
| `aspartate_chemoreception` | K05875 (Tar) only | **no** |

The consequence is the intended one and is tested: a genome carrying only a
generic chemoreceptor completes the core GIFT and not the aspartate one; a
genome carrying Tsr completes the core GIFT and not the aspartate one; a genome
carrying Tar completes both. The fix for a negative aspartate call is never to
widen K03406.

### What is deliberately *not* claimed

`aspartate_chemoreception` is named for the machinery, not the behaviour. It
claims an aspartate-responsive chemosensory input, not that the cell swims
toward aspartate — that additionally needs expression, a working motor and a
gradient. This is the regulatory counterpart of curating
`flagellar_apparatus` rather than `motility`.

### Refused

Ligand-specific claims for every other chemoeffector. K05876 (Trg) covers ribose
*and* galactose in one group and cannot separate them; K05877 (Tap) is a
dipeptide receptor whose peptide range is not resolved; K03406 covers everything
and names nothing. Tar was curated because its orthology group is anchored on a
single characterised primary ligand. The rest are refused for now, and the
refusal is the same shape as the flagellar coupling-ion refusal.

### What remains open

- Which functions are genuinely required across chemotactic lineages, as opposed
  to required in *E. coli*. The curated set is defensible for taxis systems; the
  alternative cellular functions of chemosensory-like pathways (F-class, ACF)
  may need their own circuits.
- Whether "core chemotaxis machinery" plus "flagellar apparatus" should produce a
  named chemotactic-motility trait. It should not be **curated**; it is exactly
  the kind of higher-order statement to **derive** — see
  [Derived capabilities](architecture.md#derived-capabilities).

## What is still deferred

1. Ligand-specific chemoreception beyond aspartate, pending evidence that names
   one chemoeffector per orthology group.
2. Any regulatory claim that depends on cognate pairing, gene neighbourhood,
   domain architecture or operon context. The evidence extension should be
   designed against the first concrete case that needs it, not in the abstract.
3. Chemosensory pathways whose output is not flagellar motility.
