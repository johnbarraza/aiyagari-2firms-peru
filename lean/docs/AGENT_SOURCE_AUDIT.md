# Agent Source Audit: BN26InformalityWealthPeru

## Overall status: PASS (source-first read complete; machine closeout lanes not run)

The independent source-first review was performed: the inventory below was built
by reading `anexo_matematico.tex` directly, before consulting any Lean
declaration, and was then cross-checked against the main thesis document and the
MATLAB solver of the same replication package. The consolidated machine closeout
was not run; see the Machine Audit Results section.

## Source Inventory

- Source version and digest: Anexo Matemático v10 ARz DebtPrem, Junio 2026;
  `anexo_matematico.tex`, SHA-256
  `2b7c3362e5845d109839829e8af95ec2453e20588b259efed69338a1ac7929ef`.
- Named definitions and theoretical results reviewed: el anexo no numera
  proposiciones ni teoremas. Se inventariaron 12 definiciones de modelo (proceso
  OU y discretización, preferencias y presupuesto, prima de deuda, barrera de
  acceso, HJB, agregador CES, salarios efectivos, tecnologías formal e informal,
  presupuesto del gobierno, ecuación KF, definición de equilibrio) y 8 ecuaciones
  numeradas que enuncian una afirmación derivable: `eq:Qz_construction`,
  `eq:debtprem`, `eq:ces_foc`, `eq:foc_F`/`eq:foc_I`, `eq:kkt_binding`,
  `eq:formal_foc`, `eq:wI`/`eq:PiI`, y el item (iii) de vaciamiento de mercados.
- Explicitly excluded computational or narrative material: grillas y
  discretización, esquema upwind implícito, construcción de la matriz de
  transición completa, iteración HJB, bucles de equilibrio, la sección de
  correspondencia con el código, y toda la calibración. Son material de método
  numérico o empírico, fuera del alcance normal.

## Lean Interface Comparison

- Missing paper-facing statements: la existencia del equilibrio estacionario
  (solución de HJB, distribución invariante, punto fijo de precios) y las
  condiciones de borde de drift nulo no tienen fila. Están declaradas como
  fuera de alcance en la Sección 5 del reporte de validación, no omitidas en
  silencio.
- Hidden or additional Lean assumptions: ninguna. Las ocho proposiciones exponen
  todas sus premisas en la firma; no hay registros, certificados ni envoltorios
  intermedios, y `Assumptions.lean` está vacío.
- Weakened or strengthened conclusions: la fila de oferta laboral interior es
  **más fuerte** que el texto fuente: el anexo solo escribe la fórmula, y la
  versión formalizada añade optimalidad global y unicidad del punto estacionario
  interior. La fila de vaciamiento del bien formal es más fuerte en el mismo
  sentido: prueba la identidad correcta y además caracteriza exactamente cuándo
  coincide con la impresa. Ninguna fila es más débil que su fuente.
- Source proof repairs or additional regularity conditions: tres filas usan un
  enunciado corregido respecto del impreso (agregador CES, demanda de capital
  informal, e identidad de vaciamiento). Las tres correcciones están registradas
  en `audit/source_proof_fidelity.json` con obligación de reparación y condición
  de aceptación, y explicadas en las Secciones 10 y 11 del reporte de validación.
  No se añadió ninguna condición de regularidad ajena al documento.

## Machine Audit Results

- Focused Lean build: `lake build BN26InformalityWealthPeru` exitoso, 8318
  objetivos. Barrido de `sorry`, `admit` y axiomas nuevos: limpio.
- Statement, coverage, assumption, and provenance checks: no ejecutados. Las
  líneas de auditoría semántica asistidas por modelo del protocolo v11
  (correspondencia fuente-a-Spec, cobertura de la fuente, revisión de supuestos y
  auditoría recursiva de source-record) están pendientes.
- Consolidated paper closeout: no ejecutado. La verificación con alcance de paper
  en modo rápido pasa. La verificación completa se detiene en
  `audit_conclusion_provenance.py` por falta del expediente de source-record; el
  paper de referencia `QX26AgenticDelegation` se detiene en la misma compuerta en
  este mismo entorno.

## Findings

- Audit result: las ocho filas seleccionadas representan fielmente su fuente y
  están probadas. La revisión detectó cinco correcciones necesarias en el anexo,
  una de ellas en la identidad contable que cierra el equilibrio. Ninguna afecta
  los resultados cuantitativos, porque la implementación ya usa la versión
  correcta en cuatro de los cinco casos y el quinto es una descripción de texto.
- Remaining proof or review obligations: existencia del equilibrio estacionario;
  soluciones de esquina del reparto CES; convergencia del algoritmo de bisección;
  el caso de firma informal sin capital; y las líneas de auditoría semántica
  asistidas por modelo junto con la firma humana de las ocho filas.
