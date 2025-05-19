/**
 * Utility functions for BongoSec
 */
/**
 * Safely parse JSON string
 * @param str - The JSON string to parse
 * @returns The parsed object or null if parsing fails
 */
export declare function safeJsonParse<T>(str: string): T | null;
/**
 * Check if a value is empty (null, undefined, empty string, empty array, or empty object)
 * @param value - The value to check
 * @returns boolean indicating if the value is empty
 */
export declare function isEmpty(value: any): boolean;
/**
 * Generate a random string of specified length
 * @param length - The length of the random string
 * @returns A random string
 */
export declare function generateRandomString(length: number): string;
/**
 * Deep clone an object
 * @param obj - The object to clone
 * @returns A deep clone of the object
 */
export declare function deepClone<T>(obj: T): T;
