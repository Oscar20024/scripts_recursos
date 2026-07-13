#######################################################################
# Title       : JumpScare Safe Robust
# Author      : Oscar20024
# Target      : Windows 10 / Windows 11
#
# DESCRIPCIÓN:
# - Descarga una imagen y un audio propios desde GitHub.
# - Realiza varios intentos de descarga.
# - Valida que los archivos realmente existan.
# - Espera 5 segundos.
# - Muestra temporalmente la imagen a pantalla completa.
# - Reproduce el audio.
# - NO modifica el fondo de Windows.
# - NO espera movimiento del mouse.
# - Solo elimina sus propios archivos temporales.
#
# Uso: únicamente en equipos propios o con autorización.
#######################################################################


# =====================================================================
# 1. CONFIGURACIÓN GENERAL
# =====================================================================

$ErrorActionPreference = "Stop"


# URL directa de tu imagen
$imageUrl = "https://raw.githubusercontent.com/Oscar20024/scripts_recursos/main/jumpscare.png"


# URL directa de tu audio
$wavUrl = "https://raw.githubusercontent.com/Oscar20024/scripts_recursos/main/scream.wav"


# Tiempo que espera antes de mostrar el efecto
$delayBeforeEffect = 0.5


# Tiempo que la imagen permanecerá en pantalla
$effectDuration = 5


# Carpeta temporal exclusiva del script
$workFolder = Join-Path $env:TEMP "JumpScareSafe"


# Rutas temporales
$imagePath = Join-Path $workFolder "jumpscare.png"

$wavPath = Join-Path $workFolder "scream.wav"

$logPath = Join-Path $workFolder "JumpScareSafe.log"


# =====================================================================
# 2. INTENTAR UTILIZAR TLS 1.2
#
# Esto mejora la compatibilidad con algunas versiones antiguas de
# Windows PowerShell.
#
# NO desactiva la comprobación de certificados.
# =====================================================================

try {

    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.SecurityProtocolType]::Tls12

}
catch {

    # Continúa normalmente si no es necesario.
}


# =====================================================================
# 3. CREAR CARPETA TEMPORAL
# =====================================================================

if (-not (Test-Path $workFolder)) {

    New-Item `
        -ItemType Directory `
        -Path $workFolder `
        -Force | Out-Null
}


# =====================================================================
# 4. FUNCIÓN PARA REGISTRAR INFORMACIÓN
# =====================================================================

function Write-Log {

    param (

        [Parameter(Mandatory = $true)]
        [string]$Message
    )


    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"


    $line = "[$timestamp] $Message"


    Write-Host $line


    try {

        Add-Content `
            -Path $logPath `
            -Value $line `
            -ErrorAction SilentlyContinue

    }
    catch {

        # El registro es opcional.
    }
}


# =====================================================================
# 5. FUNCIÓN PARA VALIDAR ARCHIVOS
# =====================================================================

function Test-ValidFile {

    param (

        [Parameter(Mandatory = $true)]
        [string]$Path,


        [long]$MinimumBytes = 100
    )


    # Comprobar si existe
    if (-not (Test-Path $Path)) {

        return $false
    }


    try {

        $file = Get-Item `
            -Path $Path `
            -ErrorAction Stop


        # Comprobar tamaño mínimo
        if ($file.Length -lt $MinimumBytes) {

            return $false
        }


        return $true

    }
    catch {

        return $false
    }
}


# =====================================================================
# 6. FUNCIÓN DE DESCARGA ROBUSTA
#
# Primero intenta:
# Invoke-WebRequest
#
# Si falla y BITS está disponible:
# Start-BitsTransfer
#
# No desactiva la validación HTTPS.
# =====================================================================

function Download-SafeFile {

    param (

        [Parameter(Mandatory = $true)]
        [string]$Url,


        [Parameter(Mandatory = $true)]
        [string]$Destination,


        [long]$MinimumBytes = 100
    )


    # Eliminar una posible descarga anterior incompleta
    Remove-Item `
        -Path $Destination `
        -Force `
        -ErrorAction SilentlyContinue


    # -----------------------------------------------------------------
    # MÉTODO 1: INVOKE-WEBREQUEST
    # -----------------------------------------------------------------

    for ($attempt = 1; $attempt -le 3; $attempt++) {

        try {

            Write-Log "Intentando descarga con Invoke-WebRequest. Intento $attempt de 3."


            Invoke-WebRequest `
                -Uri $Url `
                -OutFile $Destination `
                -UseBasicParsing `
                -ErrorAction Stop


            if (
                Test-ValidFile `
                    -Path $Destination `
                    -MinimumBytes $MinimumBytes
            ) {

                Write-Log "Archivo descargado correctamente."

                return $true
            }


            Write-Log "El archivo descargado no superó la validación."

        }
        catch {

            Write-Log "Error en intento ${attempt}: $($_.Exception.Message)"
        }


        # Eliminar archivo incompleto
        Remove-Item `
            -Path $Destination `
            -Force `
            -ErrorAction SilentlyContinue


        Start-Sleep -Seconds 2
    }


    # -----------------------------------------------------------------
    # MÉTODO 2: BITS
    # -----------------------------------------------------------------

    $bitsAvailable = Get-Command `
        Start-BitsTransfer `
        -ErrorAction SilentlyContinue


    if ($bitsAvailable) {

        try {

            Write-Log "Intentando descarga mediante BITS."


            Start-BitsTransfer `
                -Source $Url `
                -Destination $Destination `
                -ErrorAction Stop


            if (
                Test-ValidFile `
                    -Path $Destination `
                    -MinimumBytes $MinimumBytes
            ) {

                Write-Log "Archivo descargado correctamente mediante BITS."

                return $true
            }

        }
        catch {

            Write-Log "BITS falló: $($_.Exception.Message)"
        }
    }


    # Ningún método funcionó
    return $false
}


# =====================================================================
# 7. FUNCIÓN PARA MOSTRAR LA IMAGEN Y REPRODUCIR EL AUDIO
#
# IMPORTANTE:
# Esta función NO modifica el fondo de pantalla real de Windows.
#
# Solo crea una ventana temporal.
# =====================================================================

function Show-JumpScare {

    param (

        [Parameter(Mandatory = $true)]
        [string]$Image,


        [Parameter(Mandatory = $true)]
        [string]$Audio,


        [int]$DurationSeconds = 5
    )


    # -----------------------------------------------------------------
    # CARGAR COMPONENTES GRÁFICOS
    # -----------------------------------------------------------------

    Add-Type -AssemblyName PresentationFramework

    Add-Type -AssemblyName PresentationCore

    Add-Type -AssemblyName WindowsBase


    # -----------------------------------------------------------------
    # CREAR VENTANA
    # -----------------------------------------------------------------

    $window = New-Object System.Windows.Window


    # Sin bordes
    $window.WindowStyle = "None"


    # Maximizada
    $window.WindowState = "Maximized"


    # No permitir redimensionamiento
    $window.ResizeMode = "NoResize"


    # Mostrar encima de otras ventanas
    $window.Topmost = $true


    # Fondo negro para zonas no cubiertas
    $window.Background = "Black"


    # -----------------------------------------------------------------
    # CARGAR LA IMAGEN
    # -----------------------------------------------------------------

    $imageControl = New-Object System.Windows.Controls.Image


    $bitmap = New-Object `
        System.Windows.Media.Imaging.BitmapImage


    $bitmap.BeginInit()


    $bitmap.CacheOption = `
        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad


    $bitmap.UriSource = `
        New-Object System.Uri($Image)


    $bitmap.EndInit()


    $imageControl.Source = $bitmap


    # Usar toda la pantalla conservando proporciones
    $imageControl.Stretch = "Uniform"


    $window.Content = $imageControl


    # -----------------------------------------------------------------
    # PREPARAR AUDIO
    # -----------------------------------------------------------------

    $player = New-Object System.Media.SoundPlayer


    $player.SoundLocation = $Audio


    $player.Load()


    # -----------------------------------------------------------------
    # CREAR TEMPORIZADOR
    #
    # Al cumplirse el tiempo especificado:
    # - detiene el temporizador
    # - detiene el audio
    # - cierra la ventana
    # -----------------------------------------------------------------

    $timer = New-Object `
        System.Windows.Threading.DispatcherTimer


    $timer.Interval = `
        [TimeSpan]::FromSeconds($DurationSeconds)


    $timer.Add_Tick({

        $timer.Stop()


        try {

            $player.Stop()

        }
        catch {

            # Ignorar errores al detener audio.
        }


        $window.Close()
    })


    # -----------------------------------------------------------------
    # AL MOSTRAR LA VENTANA:
    #
    # 1. Reproducir audio
    # 2. Iniciar temporizador
    # -----------------------------------------------------------------

    $window.Add_ContentRendered({

        try {

            $player.Play()

        }
        catch {

            Write-Log "No se pudo reproducir el audio."
        }


        $timer.Start()
    })


    # -----------------------------------------------------------------
    # MOSTRAR VENTANA
    # -----------------------------------------------------------------

    $window.ShowDialog() | Out-Null
}


# =====================================================================
# 8. EJECUCIÓN PRINCIPAL
# =====================================================================

try {

    Write-Log "Iniciando JumpScare Safe."


    # -----------------------------------------------------------------
    # DESCARGAR IMAGEN
    # -----------------------------------------------------------------

    Write-Log "Descargando imagen."


    $imageDownloaded = Download-SafeFile `
        -Url $imageUrl `
        -Destination $imagePath `
        -MinimumBytes 1000


    if (-not $imageDownloaded) {

        throw "No se pudo descargar o validar la imagen."
    }


    # -----------------------------------------------------------------
    # DESCARGAR AUDIO
    # -----------------------------------------------------------------

    Write-Log "Descargando audio."


    $audioDownloaded = Download-SafeFile `
        -Url $wavUrl `
        -Destination $wavPath `
        -MinimumBytes 1000


    if (-not $audioDownloaded) {

        throw "No se pudo descargar o validar el audio."
    }


    # -----------------------------------------------------------------
    # ESPERAR UNOS SEGUNDOS
    #
    # Ya NO se necesita mover el mouse.
    # -----------------------------------------------------------------

    Write-Log "Recursos preparados correctamente."


    Write-Log "Esperando $delayBeforeEffect segundos antes del efecto."


    Start-Sleep -Seconds $delayBeforeEffect


    # -----------------------------------------------------------------
    # MOSTRAR IMAGEN Y REPRODUCIR AUDIO
    # -----------------------------------------------------------------

    Write-Log "Mostrando imagen y reproduciendo audio."


    Show-JumpScare `
        -Image $imagePath `
        -Audio $wavPath `
        -DurationSeconds $effectDuration


    Write-Log "Efecto completado correctamente."

}
catch {

    Write-Log "ERROR: $($_.Exception.Message)"


    Write-Host ""


    Write-Host `
        "No se pudo completar la ejecución." `
        -ForegroundColor Red


    Write-Host ""


    Write-Host "Detalle:"


    Write-Host $_.Exception.Message

}
finally {

    # =================================================================
    # 9. LIMPIEZA SEGURA
    #
    # Solo elimina:
    # - jumpscare.png descargado por este script
    # - scream.wav descargado por este script
    #
    # NO borra todo TEMP.
    # NO borra historiales.
    # NO vacía la papelera.
    # =================================================================


    if (Test-Path $imagePath) {

        Remove-Item `
            -Path $imagePath `
            -Force `
            -ErrorAction SilentlyContinue
    }


    if (Test-Path $wavPath) {

        Remove-Item `
            -Path $wavPath `
            -Force `
            -ErrorAction SilentlyContinue
    }


    Write-Log "Script finalizado."
}
