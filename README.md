extender
========

-extends parse_transformation for erlang

Compares exported functions from the parent module (specified by the 'extends' attribute) to those exported by the current module (being transformed). If the current module is lacking an export supported by the parent module, the transform creates and exports a function which calls the function in the parent module.
