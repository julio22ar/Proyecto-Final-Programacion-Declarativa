/* ============================================================
   PROYECTO FINAL - PROGRAMACION DECLARATIVA - CICLO 02/2026
   Sistema de solucion de integrales  -  archivo principal

   Uso:   swipl main.pl
   ============================================================ */

:- encoding(utf8).
:- multifile s/3.
:- discontiguous s/3.

:- consult(integrante1).   % validaciones + x^n, u+v, sin(x)
:- consult(integrante2).   % motor + k, k*u, tan(x)
:- consult(integrante3).   % evaluacion F(b)-F(a) + x, u-v, a^x
:- consult(integrante4).   % interfaz + k*x, cos(x), sh(x)
