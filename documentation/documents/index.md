---
layout: documentation
title: Defining documents
---

MongoMapper documents are the equivalent of models in ActiveRecord. An instantiated [MongoMapper::Document](/documentation/documents/document.html) class represents a single document in a MongoDB collection. It also provides a number of class methods used for [querying the collection](/documentation/plugins/querying.html) itself. You can embed documents inside other documents (rather than in their own collections) using the [MongoMapper::EmbeddedDocument](/documentation/documents/embedded-document.html) class.
