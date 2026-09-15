# NSC CONTROL ESCOLAR FLUTTER V1 · Edición local de evaluación

Login aprobado. Etapa actual: rediseño del panel principal

El ZIP recibido era la plantilla vacía anterior. Esta entrega implementa sus módulos y respeta la organización de `core`, `models`, `services`, `providers`, `screens`, `widgets` y `routes`. No contenía otros proyectos antiguos. Se retiraron splash, widgets vacíos, API sin implementar e ícono de relleno que no se utilizaban.

## Empezar en Windows

1. Descomprime en una carpeta nueva y ábrela en VS Code.
2. Instala el SDK de Flutter, no solo la extensión. Agrega su carpeta `bin` al PATH y reinicia VS Code. Comprueba `flutter --version`.
3. Ejecuta `PREPARAR_WINDOWS.cmd` (doble clic). Genera las plataformas, obtiene dependencias, formatea, analiza y ejecuta las pruebas. Se detiene si falla un paso.
4. Para probar con Chrome instalado, en la carpeta del proyecto ejecuta `flutter run -d chrome`.

También puedes hacerlo manualmente:

```sh
flutter create --project-name nsc_control_escolar --platforms=android,ios,web,windows .
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome
```

Las carpetas de plataformas tienen marcadores; el SDK instalado en tu equipo genera el código nativo. No uses `--overwrite`: conserva `lib` y los tests de esta entrega. Android requiere su SDK y un teléfono o emulador; Windows requiere las herramientas de Visual Studio para C++; iOS requiere macOS/Xcode. No incluye APK compilado.

## Accesos iniciales

| Perfil | Correo | Contraseña inicial |
|---|---|---|
| Administrador | administrador@nsc.local | NscDemo2026! |
| Secretaría | secretaria@nsc.local | NscDemo2026! |
| Padre | padre@nsc.local | NscDemo2026! |

Son cuentas de evaluación. Se crean solo si no hay usuarios. Se incluye una familia ficticia, un alumno ficticio y una deuda de S/ 200,00 vencida hace siete días. La sesión finaliza a los 30 minutos y no se mantiene al cerrar la aplicación.

## Funciones implementadas

- Login local, contraseñas derivadas con PBKDF2, roles y sesiones con vencimiento.
- Administrador: crear y editar usuarios, activar/desactivar cuentas, cambiar contraseña y asignar familia a padres. No puede quitarse su propio acceso.
- Familias: nombre, apoderado, documento y teléfono; alumnos: familia, grado y sección. Búsqueda y edición.
- Deudas: concepto/período, alumno, importe y fecha de vencimiento. Creación manual por el administrador, sin generación automática de mensualidades.
- Pagos: efectivo, transferencia, Yape, Plin y tarjeta. Abonos parciales, validación de saldo y referencia obligatoria salvo efectivo. No realiza cobros bancarios.
- Recibo interno automático con correlativo y datos históricos del momento del pago. Vista PDF, impresión/guardar según plataforma y compartir archivo.
- WhatsApp: abre el resumen de texto para que el usuario elija el destinatario y confirme. No adjunta PDF automáticamente. Para el archivo usa Compartir PDF y selecciona WhatsApp si la plataforma lo ofrece.
- Historial; anulación de pagos por administrador, con motivo, restauración de saldo y recibo marcado ANULADO. No se borran movimientos.
- Reporte de ingresos por rango de fechas y medio de pago; morosidad al día de consulta.
- Auditoría local de login, creación, edición, pagos y anulaciones.
- Padres: consulta de su propia familia, alumnos, deudas, pagos y recibos. Secretaría: consulta de deudas, registro de pagos, historial y recibos.

## Arquitectura

Se añadieron `deuda_model.dart`, `catalogo_service.dart`, `local_store.dart`, `deudas_screen.dart`, `form_dialog.dart` y `catalogo_view.dart` porque el módulo de saldos y la persistencia no estaban cubiertos por la plantilla. Los providers usan `ChangeNotifier` y `provider`. Los servicios concentran permisos y reglas de negocio; las pantallas presentan formularios y resultados.

El pago, su recibo y la auditoría se preparan como un único cambio de estado. La solicitud repetida conserva el mismo pago para evitar duplicados; se bloquean operaciones simultáneas en esta instancia. Las referencias de operaciones no efectivas vigentes no pueden repetirse por medio de pago. Los importes se almacenan en céntimos enteros. No se pueden editar deudas con movimientos ni cambiar de familia a un alumno que ya tenga pagos.

## Límites de esta edición

Es una implementación local para evaluar los flujos, NO un sistema listo para usar con cobros reales o datos reales de menores. Guarda un único documento JSON con SharedPreferences, apropiado aquí para demostración, no para datos financieros críticos. No tiene respaldo automático, cifrado del conjunto de datos, servidor ni sincronización. El navegador puede borrar su almacenamiento; dos dispositivos o pestañas no coordinan sus cambios. No abras simultáneamente varias instancias para registrar operaciones.

Los controles locales de roles no sustituyen autorización en un servidor: una persona con acceso al almacenamiento puede modificarlo. La auditoría local tampoco es inmutable. Para operación real hay que migrar a una base de datos transaccional con copias de seguridad, autenticación y autorización del lado del servidor y aislamiento por familia/colegio; retirar las cuentas de demostración. Los PDFs son recibos internos de evaluación y no comprobantes tributarios electrónicos.

La interfaz usa el escudo de `assets/images/logo_nsc.png`. No se reutilizaron archivos de otros proyectos.

## Validación de esta entrega

Se revisaron imports locales, estructura, balance de delimitadores del código e integridad del ZIP. La revisión de delimitadores no valida tipos ni sustituye al analizador Dart. Se incluyen pruebas para importes, saldo, pago repetido, sobrepago, anulación, permisos, aislamiento por familia, persistencia y transacción fallida; además de la pantalla de acceso.

**No se ejecutaron Flutter, flutter analyze, flutter test ni una compilación aquí: no hay SDK y no fue posible descargarlo desde este entorno.** Ejecuta el preparador para validar en tu equipo. No se certifica todavía la ejecución en Android, Windows, iOS o navegador ni las integraciones PDF/WhatsApp en un dispositivo real.

## Documentación de las dependencias

- https://pub.dev/packages/provider
- https://pub.dev/packages/shared_preferences
- https://pub.dev/packages/cryptography
- https://pub.dev/packages/pdf
- https://pub.dev/packages/printing
- https://pub.dev/packages/url_launcher
