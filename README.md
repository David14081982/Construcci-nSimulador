# BIIN

App en un solo archivo (`index.html`) conectada a Supabase. `vendor/supabase.js` es la librería oficial (supabase-js 2.119.0) y debe subirse junto con el index.

## Puesta en marcha
1. En Supabase abre **SQL Editor**, pega todo `supabase/schema.sql` y ejecútalo.
2. Abre `index.html` (doble clic o desde tu hosting) y crea tu cuenta con correo y contraseña.
3. Confirma el correo que te llega. Para pruebas puedes apagar la confirmación en **Authentication > Sign In / Providers > Email > Confirm email**.
4. En SQL Editor ejecuta la última línea de `schema.sql` con tu correo para volverte super administrador. Cierra sesión y vuelve a entrar.

## Qué se guarda en Supabase (fase 1)
- **Cuentas y roles**: `profiles` (`cliente`, `operacion`, `super_admin`). Operación solo la ve el staff; Admin solo el super administrador.
- **Catálogo**: `configuracion` (una fila con categorías, materiales, bases del cálculo y ajustes). Lo lee cualquiera; solo lo escribe el super administrador.
- **Obras y cálculos**: `obras`, privadas por usuario.

## Qué sigue en modo demo (fase 2)
Solicitudes de crédito, créditos y pagos, envíos e inventario viven en memoria (objeto `S`) y se reinician al recargar. También siguen simulados: pagos, fotos de documentos, descarga de PDF e instalación como PWA.

## Dónde tocar el código
- Conexión: objeto `SUPA` al inicio del script. Con `url` y `key` vacías la app vuelve a la demo sin base de datos.
- Catálogo: objeto `DB` (`pull` y `save`).
- Cuenta y obras: `onLogin`, `pullObras`, `pushObra` y las acciones `authGo` y `logout`.
