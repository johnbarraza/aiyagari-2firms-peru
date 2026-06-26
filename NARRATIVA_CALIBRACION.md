# Narrativa de calibración — Cómo explicar el modelo

> Basado en la última corrida (κ_z=0.42, ψ_F=52, ψ_I=34, A_I=0.98, al=0.573)

---

## 1. Qué logramos (42 corridas)

| Logro | Antes | Después | Cómo |
|-------|-------|---------|------|
| **A_I < 1** | 1.20-1.38 | **0.88-0.98** | Bajar al (0.636→0.573) + subir α_I (0.118→0.220) |
| **Gini riqueza** | 0.34-0.42 | **0.52-0.55** | Trabajo endógeno + mercados incompletos |
| **Formal-dominantes** | 3-10% | **35-40%** | ψ_F más bajo (55) + κ_z moderado |
| **p_I < 1** | 1.52 | **0.92-0.95** | ω_C=0.56 + A_I cerca de 1 |
| **K*** | 8.2-10.5 | **4.6-5.1** | Menor al reduce demanda de capital |

---

## 2. El mecanismo económico que emerge

### Cadena causal (Marcet et al., 2007)

```
Shock productivo z  →  agente productivo trabaja MÁS (efecto sustitución domina)
                   →  acumula riqueza
                   →  eventualmente trabaja MENOS (efecto riqueza, ocio es bien normal)
                   →  dispersión de riqueza entre z-alto y z-bajo
                   →  Gini > 0.50
```

### Evidencia en nuestro modelo:

| z | ℓ_F | ℓ_I | ℓ_total | Riqueza | Ocio |
|---|-----|-----|---------|---------|------|
| z_bajo (0.22) | 0.00 | 0.25 | **0.25** | bajo | 75% |
| z_alto (3.39) | 0.32 | 0.24 | **0.56** | alto | 44% |

El alto-z trabaja 2.2× más que el bajo-z. Esto genera la desigualdad de riqueza.

---

## 3. Cómo explicar cada target en la defensa

### p_I = 0.93 (bien informal más barato)
> "El precio del bien informal es menor a 1 porque la firma informal enfrenta DRS y los hogares sustituyen entre bienes vía CES con σ_C=5. El parámetro ω_C=0.56 balancea la demanda relativa para que el equilibrio de mercado dé p_I<1."

### A_I = 0.88-0.98 (PTF informal menor que formal)
> "La PTF informal es menor que la formal, consistente con la evidencia de Göbel et al. (2013) para microempresas peruanas. El sector informal compensa su menor TFP con mayor intensidad de trabajo (β_I=0.619 vs 1-al=0.427)."

### Gini riqueza = 0.52-0.55
> "Siguiendo a Marcet, Obiols-Homs y Weil (2007), el trabajo endógeno con mercados incompletos genera desigualdad de riqueza porque los agentes más productivos trabajan más horas, ahorran más, y acumulan más activos. El efecto sustitución (trabajar más cuando el salario es alto) domina al efecto riqueza con Frisch=0.38."

### T4 = 0.52 (52% horas informales)
> "La informalidad horaria surge de la interacción entre la barrera de acceso al sector formal (κ_z, que castiga a los trabajadores de baja productividad) y la ventaja comparativa del sector formal para trabajadores de alta productividad (ν_I=0.6 atenúa el ingreso informal en z-alto)."

### Tkz = 0.32-0.39 (sorting por productividad)
> "El gap de formalidad entre z-alto y z-bajo captura la barrera de acceso al sector formal. Los trabajadores más productivos enfrentan menor costo κ(z) y mayor retorno relativo en el sector formal, generando el gradiente de formalidad observado en los datos peruanos (EPEN 2025)."

---

## 4. Referencias para citar

| Paper | Para qué |
|-------|----------|
| **Marcet, Obiols-Homs & Weil (2007, JME)** | Trabajo endógeno + desigualdad: efecto riqueza vs sustitución |
| **Göbel, Grimm & Lay (2013, BCRP)** | α_I, β_I para microempresas peruanas |
| **Céspedes et al. (2014, BCRP REE-28)** | α_K=0.636 firmas formales SUNAT |
| **Hong (2022, JIE)** | ρ_z, sd_logz para Perú (ENAHO panel) |
| **Horvath (2021)** | 2 sectores F/I, CES + ocio en utilidad |
| **Achdou et al. (2017, NBER)** | Método HACT continuo |

## 5. Limitaciones documentables

1. **Gini gasto = 0.20 vs 0.40:** sin shocks transitorios de consumo. El modelo solo tiene riesgo permanente (z).
2. **K/Y = 3.1-3.4:** con al=0.573, es implicancia de la tecnología. No es target calibrado.
3. **Tgasto = 1.5 vs 1.9:** la menor brecha salarial con al=0.573 comprime la diferencia de gasto F/I.
4. **T6 gap Q1-Q5 ~ 0.05:** el canal riqueza→informalidad opera vía dV, que es débil con utilidad separable.
