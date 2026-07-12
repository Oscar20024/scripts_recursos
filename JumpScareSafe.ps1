#######################################################################
# Title       : JumpScare Safe
# Author      : Oscar20024
# Description : Muestra temporalmente una imagen a pantalla completa
#               y reproduce un audio sin modificar el fondo de Windows.
# Target      : Windows 10 / Windows 11
#######################################################################

$imageUrl = "https://raw.githubusercontent.com/Oscar20024/scripts_recursos/main/jumpscare.png"
$wavUrl   = "https://raw.githubusercontent.com/Oscar20024/scripts_recursos/main/scream.wav"

$workFolder = Join-Path $env:TEMP "JumpScareSafe"
$imagePath  = Join-Path $workFolder "jumpscare.png"
$wavPath    = Join-Path $workFolder "scream.wav"

try {

    # Crear carpeta temporal exclusiva.
    if (-not (Test-Path $workFolder)) {
        New-Item -ItemType Directory -Path $workFolder -Force | Out-Null
    }

    Write-Host "Descargando imagen..."

    Invoke-WebRequest `
        -Uri $imageUrl `
        -OutFile $imagePath `
        -ErrorAction Stop

    Write-Host "Descargando audio..."

    Invoke-WebRequest `
        -Uri $wavUrl `
        -OutFile $wavPath `
        -ErrorAction Stop


    # -------------------------------------------------------------
    # Esperar movimiento del mouse
    # -------------------------------------------------------------

    Add-Type -AssemblyName System.Windows.Forms

    $originalPosition = [System.Windows.Forms.Cursor]::Position

    Write-Host "Esperando movimiento del mouse..."

    while ($true) {

        Start-Sleep -Milliseconds 250

        $currentPosition = [System.Windows.Forms.Cursor]::Position

        if (
            $currentPosition.X -ne $originalPosition.X -or
            $currentPosition.Y -ne $originalPosition.Y
        ) {
            break
        }
    }


    # -------------------------------------------------------------
    # Cargar componentes gráficos de Windows
    # -------------------------------------------------------------

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase


    # -------------------------------------------------------------
    # Crear ventana temporal a pantalla completa
    # -------------------------------------------------------------

    $window = New-Object System.Windows.Window

    $window.WindowStyle = "None"
    $window.WindowState = "Maximized"
    $window.ResizeMode = "NoResize"
    $window.Topmost = $true
    $window.Background = "Black"


    # -------------------------------------------------------------
    # Cargar imagen
    # -------------------------------------------------------------

    $image = New-Object System.Windows.Controls.Image

    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage

    $bitmap.BeginInit()
    $bitmap.CacheOption = "OnLoad"
    $bitmap.UriSource = New-Object System.Uri($imagePath)
    $bitmap.EndInit()

    $image.Source = $bitmap
    $image.Stretch = "Uniform"

    $window.Content = $image


    # -------------------------------------------------------------
    # Preparar audio
    # -------------------------------------------------------------

    $player = New-Object System.Media.SoundPlayer
    $player.SoundLocation = $wavPath
    $player.Load()


    # -------------------------------------------------------------
    # Temporizador para cerrar automáticamente la ventana
    # después de 5 segundos.
    # -------------------------------------------------------------

    $timer = New-Object System.Windows.Threading.DispatcherTimer

    $timer.Interval = [TimeSpan]::FromSeconds(5)

    $timer.Add_Tick({

        $timer.Stop()

        $window.Close()
    })


    # -------------------------------------------------------------
    # Mostrar imagen y reproducir audio
    # -------------------------------------------------------------

    $window.Add_ContentRendered({

        $player.Play()

        $timer.Start()
    })


    $window.ShowDialog() | Out-Null
}

catch {

    Write-Host ""
    Write-Host "Se produjo un error:"
    Write-Host $_.Exception.Message
}

finally {

    # Eliminar únicamente los archivos creados por este script.

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

    if (Test-Path $workFolder) {
        Remove-Item `
            -Path $workFolder `
            -Force `
            -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "Finalizado."
}
