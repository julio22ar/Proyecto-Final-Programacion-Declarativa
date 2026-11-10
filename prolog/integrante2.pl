/* ============================================================
   PROYECTO FINAL - PROGRAMACION DECLARATIVA - CICLO 02/2026
   INTEGRANTE 2: Motor de integracion simbolica
   ============================================================
   Pendiente:
     - s/3 para:  k  (constante),  k*u,  tan(x)
     - Motor central (p. ej. integrar/2) que:
         1. reciba el texto y use validar_texto/3 (integrante 1)
         2. llame a s(x, Expr, R) con las reglas de los 4 integrantes
         3. simplifique el resultado
   Formato: ver PARTE 1 de integrante1.pl
   Reglas con el predicado del grupo:  s(Var, Funcion, Resultado)
   ============================================================ */

:- encoding(utf8).
:- multifile s/3.
:- discontiguous s/3.

% TODO
