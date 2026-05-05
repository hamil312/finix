# GUÍA DE CONFIGURACIÓN DE CONEXIÓN A POSTGRESQL

## Configuración por Plataforma

### Android Emulator
Para conectarte a tu máquina host desde el emulador de Android:
```env
DB_HOST=10.0.2.2
DB_PORT=5432
```

### iOS Simulator
Para conectarte a tu máquina host desde el simulador de iOS:
```env
DB_HOST=localhost
DB_PORT=5432
```

### Dispositivo Físico (Android/iOS)
Usa tu IP local (ejemplo: 192.168.1.100):
```env
DB_HOST=192.168.1.100
DB_PORT=5432
```

### Desarrollo Local (Desktop)
```env
DB_HOST=localhost
DB_PORT=5432
```

## Verificar que PostgreSQL está corriendo

### Windows
```powershell
# Verificar si el servicio está corriendo
Get-Service postgresql-x64-15

# O conectar con psql
psql -U postgres
```

### macOS
```bash
# Si está instalado con Homebrew
brew services list

# Conectar a la BD
psql -U postgres
```

### Linux
```bash
# Verificar el servicio
systemctl status postgresql

# Conectar a la BD
psql -U postgres
```

## Verificar el puerto correcto

```bash
# Mostrar qué puerto está escuchando PostgreSQL
psql -U postgres -c "SELECT setting FROM pg_settings WHERE name = 'port';"

# O si lo instalaste en otro puerto
psql -U postgres -p 5433 -c "SELECT version();"
```

## Solucionar "Connection refused"

1. **PostgreSQL no está corriendo**: Inicia el servicio
2. **Puerto incorrecto**: Verifica el puerto en `SELECT setting FROM pg_settings WHERE name = 'port';`
3. **Host incorrecto**: Usa `10.0.2.2` en emulador Android
4. **Firewall bloqueando**: Asegúrate que el puerto está accesible

## Probar conexión desde Terminal

```bash
# Conectar localmente
psql -U postgres -d finanzapp

# Desde otra máquina (reemplaza IP)
psql -h 192.168.1.100 -U postgres -d finanzapp
```

## Usar `flutter run` con verbose para ver errores

```bash
flutter run -v
```
