package com.example.pokemonchafa

import android.content.ComponentName
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private val vencimiento = Runnable { terminarEnvio("vencido") }
    private var canalNfc: MethodChannel? = null
    private var emulador: CardEmulation? = null
    private var resultadoEnvio: MethodChannel.Result? = null
    private var enPrimerPlano = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        canalNfc = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pokemonchafa/nfc")
        canalNfc?.setMethodCallHandler { llamada, resultado ->
            when (llamada.method) {
                "compartir" -> prepararEnvio(llamada.arguments as? ByteArray, resultado)
                "cancelarEnvio" -> {
                    terminarEnvio("cancelado")
                    resultado.success(null)
                }
                else -> resultado.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        terminarEnvio("cancelado")
        canalNfc?.setMethodCallHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        enPrimerPlano = true
    }

    override fun onPause() {
        enPrimerPlano = false
        terminarEnvio("cancelado")
        super.onPause()
    }

    private fun prepararEnvio(mensaje: ByteArray?, resultado: MethodChannel.Result) {
        if (mensaje == null || mensaje.size !in 1..32) {
            resultado.error("mensaje_invalido", null, null)
            return
        }
        if (!enPrimerPlano || resultadoEnvio != null) {
            resultado.error("no_disponible", null, null)
            return
        }
        val adaptador = NfcAdapter.getDefaultAdapter(this)
        if (adaptador == null ||
            !packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)
        ) {
            resultado.error("hce_no_disponible", null, null)
            return
        }
        if (!adaptador.isEnabled) {
            resultado.error("nfc_apagado", null, null)
            return
        }
        try {
            val servicio = ComponentName(this, ServicioNfcCriaturas::class.java)
            val emulacion = CardEmulation.getInstance(adaptador)
            if (!emulacion.setPreferredService(this, servicio)) {
                resultado.error("hce_no_disponible", null, null)
                return
            }
            emulador = emulacion
            resultadoEnvio = resultado
            protocoloNfc.ofrecer(mensaje) {
                // Deja que el servicio devuelva la respuesta antes de soltar la ruta NFC.
                handler.post { terminarEnvio("enviado", resultado) }
            }
            handler.postDelayed(vencimiento, 30_000L)
        } catch (error: RuntimeException) {
            resultado.error("no_disponible", null, null)
        }
    }

    private fun terminarEnvio(estado: String, esperado: MethodChannel.Result? = resultadoEnvio) {
        if (esperado == null || resultadoEnvio !== esperado) return
        resultadoEnvio = null
        handler.removeCallbacks(vencimiento)
        protocoloNfc.cancelar()
        runCatching { emulador?.unsetPreferredService(this) }
        emulador = null
        esperado.success(estado)
    }
}
