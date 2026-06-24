# Parámetros Cobb-Douglas formal e informal para un modelo macro de Perú

## 1. Objetivo

Este documento propone valores de elasticidades de capital y trabajo para modelar una economía con dos sectores:

\[
Y_t = Y_{F,t} + Y_{I,t}
\]

donde:

- \(F\): sector formal.
- \(I\): sector informal o proxy de microempresa informal.
- \(K\): capital.
- \(L\): trabajo.
- \(A\): productividad total de factores.

La forma general es:

\[
Y_{s,t}=A_{s,t}K_{s,t}^{\alpha_{K,s}}L_{s,t}^{\alpha_{L,s}},
\quad s\in\{F,I\}
\]

---

## 2. Fuente para el sector formal

La fuente principal para el sector formal es:

> Céspedes, N., Aquije, M. E., Sánchez, A. y Vera-Tudela, R. (2014).  
> **Productividad sectorial en el Perú: un análisis a nivel de firmas**.  
> Banco Central de Reserva del Perú, Revista Estudios Económicos, 28, 9-26.

Este paper estima una función de producción Cobb-Douglas a nivel de firmas formales peruanas usando información reportada a SUNAT entre 2002 y 2011. La especificación base es:

\[
y_{ijt}=a_{ijt}+\alpha_{k,j}k_{ijt}+\alpha_{l,j}l_{ijt}+\varepsilon_{ijt}
\]

donde \(y\), \(k\) y \(l\) están en logaritmos. El producto se aproxima como valor agregado de la firma; el capital como activo fijo neto; y el trabajo como número de trabajadores.

El estimador recomendado para un modelo macro formal es el **estimador restringido Arellano-Bond para el total de firmas**, porque impone retornos constantes a escala.

\[
\alpha_{K,F}=0.636
\]

\[
\alpha_{L,F}=0.364
\]

Por tanto:

\[
Y_F=A_FK_F^{0.636}L_F^{0.364}
\]

Como:

\[
0.636+0.364=1
\]

esta tecnología tiene **retornos constantes a escala**.

---

## 3. Fuente para el sector informal o microempresa informal

La fuente principal para aproximar el sector informal es:

> Göbel, K., Grimm, M. y Lay, J. (2013).  
> **Constrained firms, not subsistence activities: Evidence on capital returns and accumulation in Peruvian microenterprises**.  
> Banco Central de Reserva del Perú, Working Paper 2013-001.

Este paper usa ENAHO 2002-2006, específicamente el módulo de sector informal. La muestra corresponde a microempresas urbanas de trabajadores independientes o empleadores, con hasta 10 trabajadores. La base contiene información de ventas, insumos, capital, empleo y estatus legal de la unidad productiva.

La especificación estimada es:

\[
y_{it}=\alpha_i+\beta l_{it}+\gamma k_{it}+u_{it}
\]

donde \(y\) es valor agregado, \(l\) es trabajo y \(k\) es capital, todos en logaritmos.

Para todas las microempresas, los coeficientes estimados son:

\[
\alpha_{K,I}=0.118
\]

\[
\alpha_{L,I}=0.605
\]

Entonces:

\[
Y_I=A_IK_I^{0.118}L_I^{0.605}
\]

La suma es:

\[
0.118+0.605=0.723
\]

Por tanto, esta estimación sugiere **retornos decrecientes a escala** en microempresas.

Importante: estos coeficientes **no son para toda la economía peruana**. Son para microempresas urbanas del módulo de sector informal de ENAHO. Son una buena proxy para informalidad, pero no una estimación de todas las firmas informales puras.

---

## 4. Caso base recomendado para modelo macro

Si el modelo macro requiere retornos constantes a escala en ambos sectores, se recomienda mantener la estimación formal de Céspedes et al. y normalizar los coeficientes de Göbel et al. para el sector informal.

La normalización se hace así:

\[
\tilde{\alpha}_{K,I}
=
\frac{0.118}{0.118+0.605}
=
0.163
\]

\[
\tilde{\alpha}_{L,I}
=
\frac{0.605}{0.118+0.605}
=
0.837
\]

Entonces, el caso base sería:

\[
Y_F=A_FK_F^{0.636}L_F^{0.364}
\]

\[
Y_I=A_IK_I^{0.163}L_I^{0.837}
\]

Este es el caso más limpio si necesitas que ambos sectores tengan retornos constantes.

---

## 5. Tabla de valores recomendados

| Escenario | Sector formal \(K\) | Sector formal \(L\) | Sector informal \(K\) | Sector informal \(L\) | Retornos informal | Uso recomendado |
|---|---:|---:|---:|---:|---|---|
| Base CRS | 0.636 | 0.364 | 0.163 | 0.837 | Constantes | Modelo principal |
| Microempresa original | 0.636 | 0.364 | 0.118 | 0.605 | Decrecientes | Robustez fuerte |
| Comercio pequeño CRS | 0.636 | 0.364 | 0.121 | 0.879 | Constantes | Robustez baja capitalización |
| Restaurantes/alojamiento CRS | 0.636 | 0.364 | 0.099 | 0.901 | Constantes | Robustez sector informal urbano |
| Construcción CRS | 0.636 | 0.364 | 0.180 | 0.820 | Constantes | Robustez informal más capitalizada |
| Transporte CRS | 0.636 | 0.364 | 0.222 | 0.778 | Constantes | Robustez informal con más capital |

---

## 6. De dónde salen los valores de robustez sectorial

Göbel et al. reportan coeficientes por industria para microempresas. Para sectores que suelen tener mayor informalidad urbana se pueden usar como aproximaciones de robustez:

| Sector proxy informal | Capital original | Trabajo original | Suma | Capital normalizado CRS | Trabajo normalizado CRS |
|---|---:|---:|---:|---:|---:|
| Todas las microempresas | 0.118 | 0.605 | 0.723 | 0.163 | 0.837 |
| Petty trading / comercio pequeño | 0.080 | 0.582 | 0.662 | 0.121 | 0.879 |
| Wholesale/retail shops | 0.104 | 0.697 | 0.801 | 0.130 | 0.870 |
| Hoteles y restaurantes | 0.076 | 0.690 | 0.766 | 0.099 | 0.901 |
| Construcción | 0.141 | 0.642 | 0.783 | 0.180 | 0.820 |
| Transporte | 0.139 | 0.486 | 0.625 | 0.222 | 0.778 |
| Otros servicios | 0.142 | 0.558 | 0.700 | 0.203 | 0.797 |

La normalización se hace dividiendo cada coeficiente entre la suma de ambos:

\[
\alpha^{CRS}_{K,I,j}
=
\frac{\alpha_{K,I,j}}{\alpha_{K,I,j}+\alpha_{L,I,j}}
\]

\[
\alpha^{CRS}_{L,I,j}
=
\frac{\alpha_{L,I,j}}{\alpha_{K,I,j}+\alpha_{L,I,j}}
\]

---

## 7. Cómo presentar la robustez en el paper

La idea de robustez sería:

1. **Modelo principal**: formal e informal con retornos constantes.
2. **Robustez 1**: informal con retornos decrecientes usando coeficientes originales de Göbel et al.
3. **Robustez 2**: informal tipo comercio pequeño.
4. **Robustez 3**: informal tipo restaurantes/alojamiento.
5. **Robustez 4**: informal más capitalizada, usando construcción o transporte.

La especificación principal sería:

\[
Y_t=Y_{F,t}+Y_{I,t}
\]

\[
Y_{F,t}=A_{F,t}K_{F,t}^{0.636}L_{F,t}^{0.364}
\]

\[
Y_{I,t}=A_{I,t}K_{I,t}^{0.163}L_{I,t}^{0.837}
\]

La especificación con retornos decrecientes en el sector informal sería:

\[
Y_{I,t}=A_{I,t}K_{I,t}^{0.118}L_{I,t}^{0.605}
\]

La especificación de robustez para comercio pequeño sería:

\[
Y_{I,t}=A_{I,t}K_{I,t}^{0.121}L_{I,t}^{0.879}
\]

La especificación de robustez para restaurantes/alojamiento sería:

\[
Y_{I,t}=A_{I,t}K_{I,t}^{0.099}L_{I,t}^{0.901}
\]

La especificación de robustez para construcción sería:

\[
Y_{I,t}=A_{I,t}K_{I,t}^{0.180}L_{I,t}^{0.820}
\]

La especificación de robustez para transporte sería:

\[
Y_{I,t}=A_{I,t}K_{I,t}^{0.222}L_{I,t}^{0.778}
\]

---

## 8. Texto sugerido para el paper

> La producción agregada se modela como la suma de la producción formal e informal. Para el sector formal se utiliza una tecnología Cobb-Douglas con retornos constantes a escala, calibrada con el estimador restringido Arellano-Bond de Céspedes et al. (2014), quienes estiman funciones de producción a nivel de firmas formales peruanas. Dicho estimador reporta una elasticidad del capital de 0.636 y una elasticidad del trabajo de 0.364 para el total de firmas. Para el sector informal se emplea como proxy la evidencia de Göbel et al. (2013) sobre microempresas peruanas usando el módulo de sector informal de ENAHO. Los coeficientes originales para todas las microempresas son 0.118 para capital y 0.605 para trabajo, lo que implica retornos decrecientes a escala. En el modelo base se normalizan estos coeficientes para imponer retornos constantes, obteniéndose elasticidades de 0.163 para capital y 0.837 para trabajo. Como ejercicios de robustez, se consideran tanto los coeficientes originales con retornos decrecientes como normalizaciones sectoriales basadas en microempresas de comercio pequeño, restaurantes/alojamiento, construcción y transporte.

---

## 9. Interpretación económica

El sector formal queda más intensivo en capital:

\[
\alpha_{K,F}=0.636
\]

mientras que el sector informal queda más intensivo en trabajo:

\[
\alpha_{L,I}=0.837
\]

Esto es consistente con la idea de que las firmas formales tienen mayor acceso a capital, escala, crédito, tecnología y activos fijos, mientras que las unidades informales o microempresas dependen más del trabajo del propietario, trabajo familiar y bajo capital físico.

---

## 10. Replicabilidad

### Sector formal

La estimación de Céspedes et al. no es trivialmente replicable con datos públicos estándar, porque usa información de empresas formales que reportan estados financieros a SUNAT. Para replicarla exactamente se necesitaría acceso a microdatos administrativos o a una fuente equivalente con:

- ventas totales,
- costo de ventas,
- activo fijo neto,
- número de trabajadores,
- sector CIIU,
- ubicación geográfica,
- identificador de firma en panel.

Con esos datos se puede estimar:

\[
\ln Y_{ijt}
=
a_{ijt}
+
\alpha_{K,j}\ln K_{ijt}
+
\alpha_{L,j}\ln L_{ijt}
+
\varepsilon_{ijt}
\]

y aplicar MCO, efectos fijos, Arellano-Bond y Olley-Pakes.

### Sector informal

La aproximación de Göbel et al. es más replicable porque usa ENAHO 2002-2006 y el módulo de sector informal. Para replicarla se requiere construir:

- valor agregado mensual,
- capital de la unidad productiva,
- empleo,
- sector de actividad,
- panel de microempresas,
- controles del propietario y del hogar.

La dificultad principal está en limpiar las variables de capital y valor agregado, así como mantener una muestra comparable de microempresas urbanas con valores positivos de producción, capital y trabajo.

---

## 11. Recomendación final

Usar como modelo principal:

\[
Y_F=A_FK_F^{0.636}L_F^{0.364}
\]

\[
Y_I=A_IK_I^{0.163}L_I^{0.837}
\]

y como robustez principal:

\[
Y_I=A_IK_I^{0.118}L_I^{0.605}
\]

Además, probar al menos dos proxies sectoriales:

\[
Y_I=A_IK_I^{0.121}L_I^{0.879}
\]

para comercio pequeño, y:

\[
Y_I=A_IK_I^{0.099}L_I^{0.901}
\]

para restaurantes/alojamiento.

Si los resultados cambian poco entre estos escenarios, el modelo es robusto a distintas formas de parametrizar la tecnología informal.

---

## 12. Referencias

Céspedes, N., Aquije, M. E., Sánchez, A. y Vera-Tudela, R. (2014). *Productividad sectorial en el Perú: un análisis a nivel de firmas*. Banco Central de Reserva del Perú, Revista Estudios Económicos, 28, 9-26.

Göbel, K., Grimm, M. y Lay, J. (2013). *Constrained firms, not subsistence activities: Evidence on capital returns and accumulation in Peruvian microenterprises*. Banco Central de Reserva del Perú, Working Paper 2013-001.
