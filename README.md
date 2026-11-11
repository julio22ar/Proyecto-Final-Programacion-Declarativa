# Proyecto Integrales – Programación Declarativa 02/2026

**Cómo probar lo que está listo (integrantes 1, 2 y 3):** `cd prolog` → `swipl` → `?- ['integrante1.pl', 'integrante2.pl', 'integrante3.pl'].` → `?- probar_integrante1.`, `?- probar_integrante2.` y `?- probar_integrante3.`

**Arranque completo:** `cd prolog` → `swipl main.pl`. Ya carga sin errores; `integrante4.pl` todavía está vacío.

## Lo que ya está listo (Integrante 1)

| Qué | Predicado | Archivo |
|---|---|---|
| Validar el texto del usuario | `validar_texto(+Texto, -Expr, -Estado)` | `integrante1.pl` |
| Validar un término ya leído | `validar_expresion(+E, -Estado)` / `expresion_valida(+E)` | `integrante1.pl` |
| Saber si algo es constante | `es_constante(+K)`, `no_depende_de(+X, +E)` | `integrante1.pl` |
| ∫ xⁿ dx | `s(x, x^N, R)` → `x^(N+1)/(N+1)`; si `N = -1` → `log(abs(x))` | `integrante1.pl` |
| ∫ (u + v) dx | `s(x, U+V, RU+RV)` (recursiva) | `integrante1.pl` |
| ∫ sin(x) dx | `s(x, sin(x), -cos(x))` | `integrante1.pl` |

`Estado` es `ok` o `error('mensaje')`; el mensaje se puede mostrar tal cual en la interfaz.

**Pruebas:** `?- probar_integrante1.` Verifica expresiones válidas e inválidas e integrales de sus reglas.

## Lo que ya está listo (Integrante 2)

| Qué | Predicado | Archivo |
|---|---|---|
| ∫ k dx (constantes numéricas o simbólicas) | `s(x, K, K*x)`; reconoce expresiones que no dependen de `x`, por ejemplo `2*pi` | `integrante2.pl` |
| ∫ (k · u) dx | `s(x, K*U, K*RU)` (recursiva); reutiliza `s/3` para integrar `U` | `integrante2.pl` |
| ∫ tan(x) dx | `s(x, tan(x), -log(abs(cos(x))))` | `integrante2.pl` |
| Integrar una expresión escrita por el usuario | `integrar(+Texto, -Primitiva)` | `integrante2.pl` |
| Integrar y devolver estado | `integrar(+Texto, -Primitiva, -Estado)` | `integrante2.pl` |
| Integrar un término previamente validado | `integrar_expresion(+Expr, -Primitiva, -Estado)` | `integrante2.pl` |
| Simplificar una primitiva | `simplificar(+Expresion, -Resultado)` | `integrante2.pl` |
| Ejecutar pruebas del módulo | `probar_integrante2/0` (16 casos) | `integrante2.pl` |

El motor usa `validar_texto/3` del integrante 1, llama una sola vez a `s/3` para obtener la primitiva y aplica `simplificar/2`. Así podrá aprovechar las reglas adicionales de los integrantes 3 y 4 cuando se incorporen.

La simplificación incluye casos como `x^1 → x`, `A/1 → A`, `0+U → U`, `1*U → U`, `A+(-B) → A-B` y coeficientes numéricos que se pueden cancelar.

**Importante:** la regla directa `k*x` se reservó para el integrante 4; la regla de `k*u` del integrante 2 no sustituye ese caso. La evaluación numérica entre límites y la revisión de discontinuidades corresponden al integrante 3.

**Pruebas:** `?- probar_integrante2.` Incluye constantes, coeficientes, tangente, expresiones combinadas con el integrante 1 y entradas erróneas.

**Ejemplos de uso:**

```prolog
?- integrar('3*x^2 + tan(x)', R).
% Resultado esperado: R = x^3-log(abs(cos(x))).

?- integrar('2x', R, Estado).
% Resultado esperado: R = sin_resultado, Estado = error(...).
```

## Reglas para todo el grupo

1. **Todas** las integrales se escriben con el mismo predicado (formato de la Clase 12): `s(Var, Funcion, Resultado)` — `Var` siempre es `x`; el resultado va **sin** `+ C`.
2. Cada archivo `integranteN.pl` debe comenzar con:
   ```prolog
   :- multifile s/3.
   :- discontiguous s/3.
   ```
   Esto ya está presente en los archivos de los integrantes 1 y 2.
3. `main.pl` está preparado para cargar los cuatro archivos, pero el arranque completo requiere que existan `integrante3.pl` e `integrante4.pl`. Mientras tanto, probar los módulos 1 y 2 directamente.
4. Formato de las expresiones (lo que recibe Prolog):
   - Variable: `x` (minúscula) · constantes: números, `pi`, `e`.
   - Operadores: `+ - * / ^` y menos unario.
   - Funciones: `sin cos tan asin acos atan sh cosh tanh arcsinh arccosh arctanh`.
   - Se acepta `x^-1` y `x**2` (se convierten a `x^ -1` y `x^2`).
5. Las reglas de todos los integrantes deben poder invocarse a través de `s/3`, sin duplicar funciones ya implementadas. El integrante 3 puede reutilizar `integrar/3` para recibir la primitiva y su estado.

## Lo que ya está listo (Integrante 3)

| Qué | Predicado | Archivo |
|---|---|---|
| ∫ x dx | `s(x, x, x^2/2)` | `integrante3.pl` |
| ∫ (u − v) dx | `s(x, U-V, RU-RV)` (recursiva) | `integrante3.pl` |
| ∫ aˣ dx | `s(x, A^x, A^x/log(A))` con a > 0, a ≠ 1; `e^x → e^x`; `1^x → x`; a ≤ 0 no tiene regla | `integrante3.pl` |
| Integral definida F(b) − F(a) | `integral_definida(+Texto, +A, +B, -Primitiva, -Valor, -Estado)` | `integrante3.pl` |
| Área geométrica total | `area_bajo_curva(+Texto, +A, +B, -Area, -Estado)` | `integrante3.pl` |
| Validar límites | `validar_intervalo(+A, +B, -Va, -Vb, -Estado)` | `integrante3.pl` |
| Evaluar una expresión en un punto | `evaluar_en(+Expr, +X, -Valor)` | `integrante3.pl` |
| Demostración paso a paso | `demo_integral(+Texto, +A, +B)` | `integrante3.pl` |

Los límites pueden ser números o texto (`0`, `'pi'`, `'pi/2'`, `'-1.5'`). Se exige a ≤ b; si a = b el resultado es 0. Si hay error, `Valor`/`Area` = `sin_resultado` y `Estado = error('mensaje')`.

Antes de aplicar F(b) − F(a) se revisa que f sea continua en [a, b]: se evalúa f en 2000 puntos y se buscan cambios de signo en denominadores, bases con exponente negativo y cos(u) dentro de tan(u) (asíntotas verticales). `integral_definida` devuelve la integral **con signo**; `area_bajo_curva` divide el intervalo en las raíces de f y suma valores absolutos.

**Pruebas:** `?- probar_integrante3.` (33 casos: reglas, resultados positivos, negativos y cero, límites inválidos, discontinuidades y áreas).

**Ejemplos de uso:**

```prolog
?- integral_definida('x^2 - 1', 0, 2, F, V, E).
% F = x^3/3-x, V = 0.666..., E = ok.

?- area_bajo_curva('x^2 - 1', 0, 2, A, E).
% A = 2.0, E = ok.

?- integral_definida('tan(x)', 0, 2, F, V, E).
% V = sin_resultado, E = error('Discontinuidad en el intervalo cerca de x = 1.5708 ...').
```

## Para el Integrante 4 (siguiente paso)

- Reglas `s/3` de: `k*x`, `cos(x)` y `sh(x)` (para `sh` usar `sinh` al evaluar; `evaluar_en/3` ya lo traduce).
- La interfaz solo necesita llamar a `integrar/3`, `integral_definida/6` y `area_bajo_curva/5`, y mostrar el mensaje de `Estado` tal cual.
