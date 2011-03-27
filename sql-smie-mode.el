(require 'smie)

(defvar sql-smie-indent-basic 4
  "Offset for SQL indentation.")

(defconst sql-smie-tokens
  '(("SELECT" . ("select" "select distinct"))
    ("CREATE" . ("create table" "create temporary table"))
    ("ALTER"  . ("alter table"))
    ("INSERT" . ("insert into"))
    ("JOIN"   . ("inner join" "outer join"
                 "left outer join" "left join"))
    ("OP"     . ("=" "<" "<=" ">=" ">" "!=" "<>" "is" "is not"
                 "like" "not like"))
    ("GROUP"  . ("group by"))
    ("ORDER"  . ("order by"))
    ("ALT-OP" . ("add" "add column" "add index" "add key"
                 "add constraint" "alter" "alter column"
                 "modify" "modify column"))
    (keyword  . ("and" "or" "values" "where" "from" "on" "set"
                 "update" "limit" "," ";"))))

(defconst sql-smie-token-regexp
  (mapconcat (lambda (p)
               (concat "\\b" (regexp-opt (cdr p) t) "\\b"))
             sql-smie-tokens "\\|"))

(defconst sql-smie-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    '((cmd
       ("SELECT" cols "FROM" tables "WHERE" preds)
       ("INSERT" table "VALUES" preds)
       ("UPDATE" tables "SET" preds "WHERE" preds)
       ("ALTER" tables "ALT-OP")
       (cmd ";" cmd))

      (col)
      (cols (cols "," cols))

      (table)
      (tables (table)
              (tables "JOIN" tables "ON" pred))

      (pred (col "OP" col))
      (preds (pred)
             (preds "AND" preds)
             (preds "OR" preds)))
    '((assoc ";"))
    '((assoc ","))
    '((assoc "OR") (assoc "AND")))))

(defun sql-smie-rules (kind token)
  (case kind
    (:after
     (cond
      ((equal token ",") (smie-rule-separator kind))
      ((equal token "ON") sql-smie-indent-basic)
      ))
    (:before
     (cond
      ((equal token ",") (smie-rule-separator kind))
      ))
    ))

(defun sql-smie-match-group ()
  (/ (position-if-not 'null (cddr (match-data))) 2))

(defun sql-smie-forward-token ()
  (forward-comment (point-max))
  (cond
   ((looking-at sql-smie-token-regexp)
    (goto-char (match-end 0))
    (let ((group (car (nth (sql-smie-match-group) sql-smie-tokens))))
      (if (eq group 'keyword)
          (upcase (match-string-no-properties 0))
        group)))
   (t (buffer-substring-no-properties
       (point)
       (progn (skip-syntax-forward "w_")
              (point))))))

(defun sql-smie-backward-token ()
  (forward-comment (- (point)))
  (cond
   ((looking-back sql-smie-token-regexp (- (point) 20) t)
    (goto-char (match-beginning 0))
    (let ((group (car (nth (sql-smie-match-group) sql-smie-tokens))))
      (if (eq group 'keyword)
          (upcase (match-string-no-properties 0))
        group)))
   (t (buffer-substring-no-properties
       (point)
       (progn (skip-syntax-backward "w_")
              (point))))))

(define-minor-mode sql-smie-mode
  "SMIE-based indentation for SQL mode."
  nil nil nil nil
  (modify-syntax-entry ?. "_")
  (smie-setup sql-smie-grammar #'sql-smie-rules
              :forward-token #'sql-smie-forward-token
              :backward-token #'sql-smie-backward-token))


(provide 'sql-smie-mode)