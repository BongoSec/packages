# @bongosec/utils

A collection of utility functions for BongoSec projects.

## Installation

```bash
npm install @bongosec/utils
```

## Usage

```typescript
import { safeJsonParse, isEmpty, generateRandomString, deepClone } from '@bongosec/utils';

// Parse JSON safely
const data = safeJsonParse<{ name: string }>('{"name": "John"}');

// Check if value is empty
const isEmpty = isEmpty(''); // true

// Generate random string
const randomStr = generateRandomString(10);

// Deep clone object
const original = { a: 1, b: { c: 2 } };
const cloned = deepClone(original);
```

## Available Functions

### safeJsonParse<T>(str: string): T | null
Safely parse a JSON string, returning null if parsing fails.

### isEmpty(value: any): boolean
Check if a value is empty (null, undefined, empty string, empty array, or empty object).

### generateRandomString(length: number): string
Generate a random string of specified length.

### deepClone<T>(obj: T): T
Create a deep clone of an object.

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Run tests
npm test

# Lint
npm run lint
```

## License

MIT 