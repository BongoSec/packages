"use strict";
/**
 * Utility functions for BongoSec
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.deepClone = exports.generateRandomString = exports.isEmpty = exports.safeJsonParse = void 0;
/**
 * Safely parse JSON string
 * @param str - The JSON string to parse
 * @returns The parsed object or null if parsing fails
 */
function safeJsonParse(str) {
    try {
        return JSON.parse(str);
    }
    catch (error) {
        return null;
    }
}
exports.safeJsonParse = safeJsonParse;
/**
 * Check if a value is empty (null, undefined, empty string, empty array, or empty object)
 * @param value - The value to check
 * @returns boolean indicating if the value is empty
 */
function isEmpty(value) {
    if (value === null || value === undefined)
        return true;
    if (typeof value === 'string')
        return value.trim().length === 0;
    if (Array.isArray(value))
        return value.length === 0;
    if (typeof value === 'object')
        return Object.keys(value).length === 0;
    return false;
}
exports.isEmpty = isEmpty;
/**
 * Generate a random string of specified length
 * @param length - The length of the random string
 * @returns A random string
 */
function generateRandomString(length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}
exports.generateRandomString = generateRandomString;
/**
 * Deep clone an object
 * @param obj - The object to clone
 * @returns A deep clone of the object
 */
function deepClone(obj) {
    return JSON.parse(JSON.stringify(obj));
}
exports.deepClone = deepClone;
