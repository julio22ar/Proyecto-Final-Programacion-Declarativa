# Proyecto Integrales – Programación Declarativa 02/2026

Cómo correrlo: `cd prolog` → `swipl main.pl` → `?- probar_integrante1.`

## Lo que ya está listo (Integrante 1)

| Qué | Predicado | Archivo |
|---|---|---|
| Validar el texto del usuario | `validar_texto(+Texto, -Expr, -Estado)` | integrante1.pl |
| Validar un término ya leído | `validar_expresion(+E, -Estado)` / `expresion_valida(+E)` | integrante1.pl |
| Saber si algo es constante | `es_constante(+K)`, `no_depende_de(+X, +E)` | integrante1.pl |
| ∫ xⁿ dx | `s(x, x^N, R)` → `x^(N+1)/(N+1)`; si N = -1 → `log(abs(x))` | integrante1.pl |
| ∫ (u + v) dx | `s(x, U+V, RU+RV)` (recursiva) | integrante1.pl |
| ∫ sin(x) dx | `s(x, sin(x), -cos(x))` | integrante1.pl |

`Estado` es `ok` o `error('mensaje')`; el mensaje se puede mostrar tal cual en la interfaz.

## Reglas para todo el grupo

1. **Todas** las integrales se escriben con el mismo predicado (formato de la Clase 12):
   `s(Var, Funcion, Resultado)` — Var siempre es `x`, el resultado va **sin** `+ C`.
2. Cada archivo `integranteN.pl` empieza con:
   ```prolog
   :- multifile s/3.
   :- discontiguous s/3.
   ```
   (ya está puesto en los cuatro archivos).
3. `main.pl` carga los cuatro archivos; no hay que tocarlo.
4. Formato de las expresiones (lo que recibe Prolog):
   - variable: `x` (minúscula) · constantes: números, `pi`, `e`
   - operadores: `+ - * / ^` y menos unario
   - funciones: `sin cos tan asin acos atan sh cosh tanh arcsinh arccosh arctanh`
   - se acepta `x^-1` y `x**2` (se convierten a `x^ -1` y `x^2`)

## Para el Integrante 2 (siguiente paso)

- Reglas `s/3` de: `k`, `k*u`, `tan(x)` (puede usar `es_constante/1`).
- Motor, por ejemplo:
  ```prolog
  integrar(Texto, Resultado, Estado) :-
      validar_texto(Texto, Expr, Estado0),
      (   Estado0 \== ok -> Estado = Estado0
      ;   once(s(x, Expr, R0))      % once: evita respuestas repetidas
      ->  simplificar(R0, Resultado), Estado = ok
      ;   Estado = error('No se encontro regla para integrar')
      ).
  ```
- Simplificación: hay resultados como `x^1/1` o `x^3/3+ -cos(x)` que conviene limpiar
  (`x^1 → x`, `A/1 → A`, `A + -B → A - B`).
