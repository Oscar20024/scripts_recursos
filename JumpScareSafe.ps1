#######################################################################
# Title       : JumpScare Safe
# Author      : Oscar20024
# Description : Descarga una imagen y un audio propios desde GitHub,
#               espera movimiento del mouse, cambia temporalmente el
#               fondo de pantalla, reproduce el audio y finalmente
#               restaura el fondo original.
#
# Target      : Windows 10 / Windows 11
#
# IMPORTANTE:
# - No modifica el volumen.
# - No borra historiales.
# - No vacía la papelera.
# - No borra todo TEMP.
# - Solo elimina los archivos temporales creados por este script.
#######################################################################


# =====================================================================
# 1. CONFIGURACIÓN DE LOS RECURSOS
# =====================================================================

$imageUrl = "https://raw.githubusercontent.com/Oscar20024/scripts_recursos/main/jumpscare.png"

$wavUrl = "https://raw.githubusercontent.com/Oscar20024/scripts_recursos/main/scream.wav"


# =====================================================================
# 2. CREAR UNA CARPETA TEMPORAL EXCLUSIVA PARA ESTE SCRIPT
# =====================================================================

$workFolder = Join-Path $env:TEMP "JumpScareSafe"

$imagePath = Join-Path $workFolder "jumpscare.png"

$wavPath = Join-Path $workFolder "scream.wav"


try {

    if (-not (Test-Path $workFolder)) {

        New-Item `
            -ItemType Directory `
            -Path $workFolder `
            -Force | Out-Null
    }


    # =================================================================
    # 3. DESCARGAR LA IMAGEN
    # =================================================================

    Write-Host "Descargando imagen..."

    Invoke-WebRequest `
        -Uri $imageUrl `
        -OutFile $imagePath `
        -ErrorAction Stop


    # =================================================================
    # 4. DESCARGAR EL AUDIO
    # =================================================================

    Write-Host "Descargando audio..."

    Invoke-WebRequest `
        -Uri $wavUrl `
        -OutFile $wavPath `
        -ErrorAction Stop


    # =================================================================
    # 5. VERIFICAR QUE LOS ARCHIVOS FUERON DESCARGADOS
    # =================================================================

    if (-not (Test-Path $imagePath)) {

        throw "No se pudo encontrar la imagen descargada."
    }


    if (-not (Test-Path $wavPath)) {

        throw "No se pudo encontrar el audio descargado."
    }


    # =================================================================
    # 6. GUARDAR LA CONFIGURACIÓN ORIGINAL DEL FONDO
    # =================================================================

    $desktopSettings = Get-ItemProperty `
        -Path "HKCU:\Control Panel\Desktop" `
        -ErrorAction SilentlyContinue


    $originalWallpaper = $desktopSettings.Wallpaper

    $originalWallpaperStyle = $desktopSettings.WallpaperStyle

    $originalTileWallpaper = $desktopSettings.TileWallpaper


    # =================================================================
    # 7. FUNCIÓN PARA CAMBIAR EL FONDO DE PANTALLA
    # =================================================================

    function Set-WallPaper {

        param (

            [Parameter(Mandatory = $true)]
            [string]$Image,

            [ValidateSet(
                "Fill",
                "Fit",
                "Stretch",
                "Tile",
                "Center",
                "Span"
            )]
            [string]$Style = "Center"
        )


        $WallpaperStyle = switch ($Style) {

            "Fill" {
                "10"
            }

            "Fit" {
                "6"
            }

            "Stretch" {
                "2"
            }

            "Tile" {
                "0"
            }

            "Center" {
                "0"
            }

            "Span" {
                "22"
            }
        }


        if ($Style -eq "Tile") {

            Set-ItemProperty `
                -Path "HKCU:\Control Panel\Desktop" `
                -Name WallpaperStyle `
                -Value $WallpaperStyle

            Set-ItemProperty `
                -Path "HKCU:\Control Panel\Desktop" `
                -Name TileWallpaper `
                -Value "1"
        }

        else {

            Set-ItemProperty `
                -Path "HKCU:\Control Panel\Desktop" `
                -Name WallpaperStyle `
                -Value $WallpaperStyle

            Set-ItemProperty `
                -Path "HKCU:\Control Panel\Desktop" `
                -Name TileWallpaper `
                -Value "0"
        }


        if (-not ("WallpaperManager" -as [type])) {

            Add-Type -TypeDefinition @"

using System;
using System.Runtime.InteropServices;

public class WallpaperManager
{
    [DllImport(
        "user32.dll",
        CharSet = CharSet.Unicode,
        SetLastError = true
    )]

    public static extern bool SystemParametersInfo(
        int uAction,
        int uParam,
        string lpvParam,
        int fuWinIni
    );
}

"@
        }


        $SPI_SETDESKWALLPAPER = 0x0014

        $SPIF_UPDATEINIFILE = 0x01

        $SPIF_SENDCHANGE = 0x02

        $flags = $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE


        [WallpaperManager]::SystemParametersInfo(
            $SPI_SETDESKWALLPAPER,
            0,
            $Image,
            $flags
        ) | Out-Null
    }


    # =================================================================
    # 8. FUNCIÓN PARA ESPERAR MOVIMIENTO DEL MOUSE
    #
    # Esperará como máximo 60 segundos.
    # Si nadie mueve el mouse, el script termina normalmente.
    # =================================================================

    function Wait-ForMouseMovement {

        param (

            [int]$MaximumWaitSeconds = 60
        )


        Add-Type -AssemblyName System.Windows.Forms


        $originalPosition = [System.Windows.Forms.Cursor]::Position

        $startTime = Get-Date


        Write-Host "Esperando movimiento del mouse..."


        while ($true) {

            Start-Sleep -Milliseconds 250


            $currentPosition = [System.Windows.Forms.Cursor]::Position


            if (
                $currentPosition.X -ne $originalPosition.X -or
                $currentPosition.Y -ne $originalPosition.Y
            ) {

                return $true
            }


            $elapsedSeconds = (
                (Get-Date) - $startTime
            ).TotalSeconds


            if ($elapsedSeconds -ge $MaximumWaitSeconds) {

                return $false
            }
        }
    }


    # =================================================================
    # 9. FUNCIÓN PARA REPRODUCIR EL ARCHIVO WAV
    # =================================================================

    function Play-WAV {

        param (

            [Parameter(Mandatory = $true)]
            [string]$Path
        )


        if (-not (Test-Path $Path)) {

            throw "No se encontró el archivo WAV."
        }


        $player = New-Object System.Media.SoundPlayer

        $player.SoundLocation = $Path

        $player.Load()

        $player.PlaySync()
    }


    # =================================================================
    # 10. ESPERAR HASTA DETECTAR MOVIMIENTO DEL MOUSE
    # =================================================================

    $mouseMoved = Wait-ForMouseMovement -MaximumWaitSeconds 60


    if (-not $mouseMoved) {

        Write-Host "No se detectó movimiento. Finalizando."

        return
    }


    # =================================================================
    # 11. CAMBIAR TEMPORALMENTE EL FONDO
    # =================================================================

    Set-WallPaper `
        -Image $imagePath `
        -Style Center


    # =================================================================
    # 12. REPRODUCIR EL AUDIO
    #
    # Este script NO modifica el volumen del equipo.
    # =================================================================

    Play-WAV -Path $wavPath


    # =================================================================
    # 13. ESPERAR DOS SEGUNDOS
    # =================================================================

    Start-Sleep -Seconds 2
}

catch {

    Write-Host ""

    Write-Host "Se produjo un error:"

    Write-Host $_.Exception.Message
}

finally {

    # =================================================================
    # 14. RESTAURAR EL FONDO ORIGINAL
    # =================================================================

    try {

        if (
            $originalWallpaper -and
            (Test-Path $originalWallpaper)
        ) {

            Set-ItemProperty `
                -Path "HKCU:\Control Panel\Desktop" `
                -Name WallpaperStyle `
                -Value $originalWallpaperStyle `
                -ErrorAction SilentlyContinue


            Set-ItemProperty `
                -Path "HKCU:\Control Panel\Desktop" `
                -Name TileWallpaper `
                -Value $originalTileWallpaper `
                -ErrorAction SilentlyContinue


            if ("WallpaperManager" -as [type]) {

                $SPI_SETDESKWALLPAPER = 0x0014

                $SPIF_UPDATEINIFILE = 0x01

                $SPIF_SENDCHANGE = 0x02

                $flags = $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE


                [WallpaperManager]::SystemParametersInfo(
                    $SPI_SETDESKWALLPAPER,
                    0,
                    $originalWallpaper,
                    $flags
                ) | Out-Null
            }
        }
    }

    catch {

        Write-Host "No se pudo restaurar automáticamente el fondo."
    }


    # =================================================================
    # 15. ELIMINAR ÚNICAMENTE LOS ARCHIVOS CREADOS POR ESTE SCRIPT
    #
    # No borra todo TEMP.
    # No borra historiales.
    # No vacía la papelera.
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


    if (Test-Path $workFolder) {

        Remove-Item `
            -Path $workFolder `
            -Force `
            -ErrorAction SilentlyContinue
    }


    Write-Host ""

    Write-Host "Finalizado."
}