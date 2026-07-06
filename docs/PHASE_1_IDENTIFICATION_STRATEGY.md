# Fase 1 - Estrategia de identificacion

Fecha: 2026-07-06  
Estado: propuesta para aprobacion antes de Fase 2  
Alcance: no se implemento codigo, no se reproceso el panel y no se modificaron modelos.

## 1. Lectura econometrica general

El repositorio debe avanzar con una estrategia de dos niveles. El Nivel 1 usa el panel completo como evidencia observacional para America Latina y el Caribe; debe hablar siempre de asociaciones condicionales, no de efectos causales. El Nivel 2 debe separarse como capitulo cuasi-causal, limitado a eventos de politica con fecha clara y con soporte suficiente en el panel limpio.

El panel actual no permite una estrategia causal general tipo Callaway-Sant'Anna o Sun-Abraham para los 21 paises con proteccion social observada, porque no existe una variable de adopcion/reforma armonizada por pais y anio. Tampoco hay, dentro del repositorio, un instrumento defendible para cobertura de proteccion social: los candidatos naturales, como ciclos politicos, precios de commodities o espacio fiscal, afectarian pobreza por canales directos. Por tanto, la mejor arquitectura cientifica es: asociacional rigurosa para el panel completo y estudio de eventos documentados para un subconjunto pequeno.

## 2. Eventos de politica encontrados

| Pais | Politica | Fecha anual propuesta | Fuente y timing | Entra al Nivel 2 | Razon |
| --- | --- | ---: | --- | --- | --- |
| Bolivia | Renta Dignidad | 2008 | Ley 3791 promulga la Renta Universal de Vejez el 28 de noviembre de 2007 y establece vigencia desde el 1 de enero de 2008; el DS 29400 fija inicio de pagos el 1 de febrero de 2008. Fuentes: [Ley 3791](https://www.lexivox.org/norms/BO-L-3791.html), [DS 29400](https://www.lexivox.org/norms/BO-DS-29400.html). | Si, nucleo | Timing exacto, cobertura anual suficiente: ventana +/-5 con 11 observaciones de pobreza, 9 de informalidad y 6 de cobertura social. |
| Peru | JUNTOS | 2005 | El programa JUNTOS es el programa nacional de transferencias condicionadas para hogares pobres; la pagina institucional actual confirma mandato y poblacion objetivo. La literatura de evaluacion del Banco Mundial identifica JUNTOS como programa iniciado en 2005. Fuente institucional: [Gob.pe JUNTOS](https://www.gob.pe/juntos). Fuente tecnica a archivar antes de estimar: Perova y Vakis (2009), Banco Mundial. | Si, nucleo condicionado | Buena cobertura de pobreza y controles en +/-5; cobertura de proteccion social es limitada cerca de 2005, por lo que el evento debe modelarse como adopcion de programa, no como variacion continua de cobertura social. |
| Brasil | Bolsa Familia | 2004 | Programa federal de transferencias condicionado; fuente institucional: [MDS Bolsa Familia](https://www.gov.br/mds/pt-br/acoes-e-programas/bolsa-familia). Timing legal a archivar antes de estimar: MP 132 del 20 de octubre de 2003 y Ley 10.836 del 9 de enero de 2004. | Si, pero secundario | Evento ampliamente documentado y cobertura de pobreza adecuada; no hay cobertura suficiente de informalidad ni proteccion social en la ventana temprana, por lo que solo sirve para un event-study de pobreza con controles macro. |
| Chile | Chile Solidario | 2004 legal, 2002 operativo | La Ley 19.949 crea el sistema Chile Solidario y dispone aplicacion gradual desde 2004. Fuente: [Biblioteca del Congreso Nacional de Chile, Ley 19.949](https://www.bcn.cl/leychile/navegar?idNorma=226081). | No en nucleo | Timing sustantivo 2002 vs legal 2004 no es completamente limpio para un panel anual; ademas la ventana +/-5 tiene 0 observaciones de informalidad, 1 de proteccion social y pocos controles. Puede quedar como apendice narrativo o robustez de pobreza solamente. |

No se recomienda incluir mas paises en Fase 2 con la informacion actual. Panama, El Salvador, Republica Dominicana, Paraguay y Costa Rica pueden ser investigados despues, pero no conviene forzar eventos si no se documentan rapidamente con una fuente seria y fecha indiscutible.

## 3. Nivel 1: panel completo observacional

La especificacion principal debe mantener el TWFE actual:

$$
Y_{it} = \beta_1 Informality_{it} + \beta_2 SP_{it} + \beta_3 X_{it} + \mu_i + \lambda_t + \varepsilon_{it}
$$

donde \(Y_{it}\) es pobreza monetaria, con pobreza extrema como resultado secundario; \(SP_{it}\) es cobertura de proteccion social; \(X_{it}\) incluye log PIB per capita, Gini y desempleo; \(\mu_i\) son efectos fijos de pais y \(\lambda_t\) efectos fijos de anio.

Inferencia recomendada:

- Mantener errores agrupados por pais, pero reportar p-valores wild cluster bootstrap por el bajo numero de clusters efectivos, actualmente 17 en la muestra completa del modelo principal.
- Reportar Driscoll-Kraay como alternativa principal de robustez porque ya hay evidencia de dependencia transversal y autocorrelacion.
- Incluir sensibilidad Oster (2019) para el coeficiente de proteccion social. La salida debe reportar \(R_{max}\), \(\delta\) necesario para llevar \(\beta_2\) a cero y el intervalo ajustado bajo \(\delta=1\). El coeficiente base a evaluar es aproximadamente -0.102 con p=0.0057.
- Agregar regresion cuantilica panel para evaluar heterogeneidad a lo largo de la distribucion de pobreza. La interpretacion correcta no es "efecto en individuos pobres", sino asociacion en pais-anios ubicados en cuantiles altos o bajos de la tasa de pobreza.

Decision metodologica pendiente para Fase 2:

1. Opcion preferida: Canay (2011) con efectos fijos residualizados y cuantiles \(\tau = 0.25, 0.50, 0.75\). Es transparente y defendible para un panel pequeno.
2. Opcion alternativa: cuantiles panel penalizados con efectos fijos, si la implementacion R resulta estable. Es mas flexible, pero menos facil de explicar y mas sensible al tamano de muestra.

## 4. Nivel 2: eventos de politica cuasi-causales

La especificacion recomendada es un event-study apilado, no un staggered DiD general:

$$
Y_{ist} = \alpha_i^s + \lambda_t^s + \sum_{\ell=-K,\ell \ne -1}^{L} \gamma_{\ell}
\left(Treated_i^s \times 1[t - T_s = \ell]\right) + X_{it}'\delta + \varepsilon_{ist}
$$

Cada stack \(s\) corresponde a un evento-pais: Bolivia 2008, Peru 2005 y, si se aprueba, Brasil 2004. El grupo de comparacion debe formarse con paises del panel que no tengan un evento calificado dentro de la misma ventana. La categoria omitida sera \(\ell=-1\). La ventana principal debe ser \(K=L=5\), con robustez en +/-3 y +/-8 si la cobertura lo permite.

Resultados principales: pobreza monetaria y pobreza extrema. Informalidad puede incluirse solo donde exista cobertura suficiente; por ahora Bolivia y Peru son razonables, Brasil no. La lectura cuasi-causal requiere demostrar tendencias paralelas pre-evento; si los leads son grandes o sistematicos, el resultado debe presentarse como evidencia descriptiva de evento, no como DiD causal.

Inferencia: pais-cluster, wild cluster bootstrap y, dado el numero minimo de tratados, una prueba de aleatorizacion/placebo por pais-anio si la muestra final lo permite.

## 5. Datos adicionales necesarios antes de Fase 2

No se necesita reprocesar el panel para comenzar. Si se aprueba la estrategia, Fase 2 debe usar el CSV limpio existente.

Si se quiere fortalecer el Nivel 2, hacen falta tres insumos pequenos y controlados:

- Archivar fuentes legales exactas para Peru JUNTOS y Brasil Bolsa Familia dentro de la bibliografia del paper.
- Crear una tabla manual de eventos con `iso3`, `event_year`, `policy_name`, `source_url`, `event_confidence` y notas de cobertura.
- Si el capitulo cuasi-causal aspira a una lectura fuerte, conseguir series externas de cobertura/beneficiarios por pais-anio para Renta Dignidad, JUNTOS y Bolsa Familia. Sin intensidad de tratamiento, el diseno identifica cambios agregados alrededor de adopciones nacionales, no dosis de proteccion social.

## 6. Recomendacion para aprobacion

La recomendacion tecnica es aprobar:

- Nivel 1 como panel TWFE observacional con wild cluster bootstrap, Driscoll-Kraay, Oster y cuantiles panel.
- Nivel 2 nucleo con Bolivia 2008 y Peru 2005.
- Brasil 2004 como extension secundaria de pobreza, no como modelo de informalidad.
- Chile Solidario fuera del nucleo, salvo como apendice narrativo o placebo descriptivo.

Con esta arquitectura, el paper evita sobreprometer causalidad en el panel completo y reserva el lenguaje cuasi-causal para eventos con timing defendible.
