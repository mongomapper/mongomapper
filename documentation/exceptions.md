---
layout: documentation
title: Exceptions
---

All MongoMapper exceptions inherit from MongoMapper::Error, which inherits from Ruby's StandardError.

-   **MongoMapper::DocumentNotFound**: Raised when document expected to exist, but not found in database (ie: find!).
-   **MongoMapper::InvalidScheme**: Raised when connecting using URI with incorrect scheme.
-   **MongoMapper::NotSupported**: Raised when trying to do something not supported, mostly with embedded documents.
-   **MongoMapper::DocumentNotValid**: Raised when creating, updating or saving with ! and a document is not valid.
-   **MongoMapper::AccessibleOrProtected**: Raised when attr\_accessible and attr\_protected are both called on the same model.
