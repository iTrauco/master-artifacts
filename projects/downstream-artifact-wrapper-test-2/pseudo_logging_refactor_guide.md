# Pseudo Implementation Guide for Refactoring the Logging Module

## 1. Overview

This guide outlines the key steps to refactor the logging system to improve traceability, configurability, and maintainability.

## 2. Directory Structure

```
server/
├── config/
│   └── logger.js
├── middleware/
│   └── request-logger.js
├── utils/
│   └── logger/
│       ├── index.js
│       └── formatter.js
test/
└── unit/
    └── utils/
        └── logger/
            └── index.test.js
```

## 3. Core Refactor Targets

### 3.1 `server/config/logger.js`

Create a centralized configuration for log levels, transports, and formats.

```js
// Pseudocode
module.exports = {
  level: 'info',
  format: combine(timestamp(), json()),
  transports: [new Console(), new File({ filename: 'app.log' })]
};
```

### 3.2 `server/utils/logger/index.js`

Export a logger instance configured with the centralized config.

```js
// Pseudocode
const config = require('../../config/logger');
const { createLogger } = require('winston');

const logger = createLogger(config);
module.exports = logger;
```

### 3.3 `server/middleware/request-logger.js`

Log each incoming HTTP request with method, URL, and timestamp.

```js
// Pseudocode
module.exports = function (req, res, next) {
  logger.info(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
};
```

## 4. Test Plan

### 4.1 `test/unit/utils/logger/index.test.js`

Test that the logger calls the correct methods and formats outputs properly.

```js
// Pseudocode
describe('Logger Utility', () => {
  it('should format messages correctly', () => {
    const msg = formatMessage('test');
    expect(msg).toMatch(/\d{4}-\d{2}-\d{2}T/);
  });
});
```
