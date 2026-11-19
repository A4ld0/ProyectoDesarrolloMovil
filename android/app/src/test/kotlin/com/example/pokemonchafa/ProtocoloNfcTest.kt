package com.example.pokemonchafa

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class ProtocoloNfcTest {
    private val seleccionar = byteArrayOf(
        0, 0xA4.toByte(), 4, 0, 6, 0xF0.toByte(), 0x50, 0x4B, 0x43, 0x48, 1, 0,
    )
    private val confirmar = byteArrayOf(0x80.toByte(), 0x20, 0, 0, 0)
    private val exito = byteArrayOf(0x90.toByte(), 0)
    private val sinOferta = byteArrayOf(0x69, 0x85.toByte())
    private val mensaje = byteArrayOf(1) + "nubin".encodeToByteArray()

    @Test
    fun unaOfertaSeConfirmaUnaSolaVez() {
        val protocolo = ProtocoloNfc()
        var confirmaciones = 0
        protocolo.ofrecer(mensaje) { confirmaciones++ }

        assertArrayEquals(sinOferta, protocolo.responder(confirmar))
        assertArrayEquals(mensaje + exito, protocolo.responder(seleccionar))
        assertEquals(0, confirmaciones)
        assertArrayEquals(exito, protocolo.responder(confirmar))
        assertEquals(1, confirmaciones)
        assertArrayEquals(sinOferta, protocolo.responder(seleccionar))
        assertArrayEquals(sinOferta, protocolo.responder(confirmar))
    }

    @Test
    fun unaDesconexionExigeSeleccionNuevaYCancelarCierraLaOferta() {
        val protocolo = ProtocoloNfc()
        var confirmaciones = 0
        protocolo.ofrecer(mensaje) { confirmaciones++ }
        protocolo.responder(seleccionar)
        protocolo.desconectar()
        assertArrayEquals(sinOferta, protocolo.responder(confirmar))
        assertArrayEquals(mensaje + exito, protocolo.responder(seleccionar))

        protocolo.cancelar()
        assertArrayEquals(sinOferta, protocolo.responder(confirmar))
        assertArrayEquals(sinOferta, protocolo.responder(seleccionar))
        assertEquals(0, confirmaciones)
    }
}
