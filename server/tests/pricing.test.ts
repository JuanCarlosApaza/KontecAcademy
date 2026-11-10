import { describe, expect, it } from 'vitest';
import { effectivePriceOf, offerPriceOf } from '../src/domain/catalog.js';

/**
 * REGRESIÓN: la semántica de precios se había invertido una vez
 * (el front tachaba el precio de oferta en vez del general, y como la
 * oferta venía MENOR que el general la condición nunca se cumplía).
 *
 * Regla: `price` = precio GENERAL · `compareAtPrice` = precio de OFERTA.
 * Solo hay oferta real cuando la oferta es > 0 y MENOR que el general.
 * Es la MISMA regla que el front (course_display.dart).
 */
describe('regla de precios del dominio', () => {
  it('oferta válida (oferta < general) → se cobra la oferta', () => {
    expect(offerPriceOf({ price: 60, compareAtPrice: 50 })).toBe(50);
    expect(effectivePriceOf({ price: 60, compareAtPrice: 50 })).toBe(50);
  });

  it('sin segundo precio → se cobra el general', () => {
    expect(offerPriceOf({ price: 60, compareAtPrice: null })).toBeNull();
    expect(effectivePriceOf({ price: 60, compareAtPrice: null })).toBe(60);
  });

  it('oferta MAYOR que el general → datos inconsistentes, se ignora', () => {
    expect(offerPriceOf({ price: 150, compareAtPrice: 200 })).toBeNull();
    expect(effectivePriceOf({ price: 150, compareAtPrice: 200 })).toBe(150);
  });

  it('oferta igual al general → no es un descuento', () => {
    expect(offerPriceOf({ price: 100, compareAtPrice: 100 })).toBeNull();
    expect(effectivePriceOf({ price: 100, compareAtPrice: 100 })).toBe(100);
  });

  it('oferta en 0 o negativa → se ignora', () => {
    expect(offerPriceOf({ price: 60, compareAtPrice: 0 })).toBeNull();
    expect(offerPriceOf({ price: 60, compareAtPrice: -10 })).toBeNull();
  });
});
