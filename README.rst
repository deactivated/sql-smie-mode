================
sql-smie-mode.el
================

`sql-smie-mode` is an Emacs minor mode for indenting SQL.  It depends
on the SMIE library introduced in Emacs 23.3.

The mode is currently incomplete, but I think it works better than
`sql-indent.el` in many cases already.


Usage
-----

Place `sql-smie-mode.el` in a directory on your load path and add the
following to your emacs init file:

  (require 'sql-smie-mode)
  (add-hook 'sql-mode-hook 'sql-smie-mode)
