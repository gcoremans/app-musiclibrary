;;;;;;;;;;;;;;;;;;;
;;; delta messenger
(in-package :delta-messenger)

(push (make-instance 'delta-logging-handler) *delta-handlers*) ;; enable if delta messages should be logged on terminal
(add-delta-messenger "http://delta-notifier/")
(setf *log-delta-messenger-message-bus-processing* nil) ;; set to t for extra messages for debugging delta messenger

;;;;;;;;;;;;;;;;;
;;; configuration
(in-package :client)
(setf *log-sparql-query-roundtrip* t) ; change nil to t for logging requests to virtuoso (and the response)
(setf *backend* "http://triplestore:8890/sparql")

(in-package :server)
(setf *log-incoming-requests-p* t) ; change nil to t for logging all incoming requests

;;;;;;;;;;;;;;;;
;;; prefix types
(in-package :type-cache)

(add-type-for-prefix "http://mu.semte.ch/sessions/" "http://mu.semte.ch/vocabularies/session/Session") ; each session URI will be handled for updates as if it had this mussession:Session type

;;;;;;;;;;;;;;;;;
;;; access rights

(in-package :acl)

;; these three reset the configuration, they are likely not necessary
(defparameter *access-specifications* nil)
(defparameter *graphs* nil)
(defparameter *rights* nil)

;; Prefixes used in the constraints below (not in the SPARQL queries)
(define-prefixes
  ;; Core
  :mu "http://mu.semte.ch/vocabularies/core/"
  :session "http://mu.semte.ch/vocabularies/session/"
  :ext "http://mu.semte.ch/vocabularies/ext/"
  :foaf "http://xmlns.com/foaf/0.1/"
  ;; Custom prefix URIs here, prefix casing is ignored
  )


;;;;;;;;;
;; Graphs
;;
;; These are the graph specifications known in the system.  No
;; guarantees are given as to what content is readable from a graph.  If
;; two graphs are nearly identitacl and have the same name, perhaps the
;; specifications can be folded too.  This could help when building
;; indexes.

(define-graph public ("http://mu.semte.ch/graphs/public")
  (_ -> _)) ; public allows ANY TYPE -> ANY PREDICATE in the direction
            ; of the arrow

(define-graph users ("http://mu.semte.ch/graphs/users")
  ("foaf:OnlineAccount"
   -> "foaf:accountName")
  ("foaf:Person"
   -> "foaf:name"
   -> "foaf:account"))

(define-graph collections ("http://mu.semte.ch/graphs/collections/")
  (_ -> _))

;; Example:
;; (define-graph company ("http://mu.semte.ch/graphs/companies/")
;;   ("foaf:OnlineAccount"
;;    -> "foaf:accountName"
;;    -> "foaf:accountServiceHomepage")
;;   ("foaf:Group"
;;    -> "foaf:name"
;;    -> "foaf:member"))


;;;;;;;;;;;;;
;; User roles

(supply-allowed-group "public")

(supply-allowed-group "user"
  :parameters ("user")
  :query "PREFIX session: <http://mu.semte.ch/vocabularies/session/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          SELECT DISTINCT ?user ?account WHERE {
            <SESSION_ID> session:account ?account.
            ?account foaf:accountName ?user.
          }")

(grant (read write)
       :to-graph collections
       :for-allowed-group "user")

(grant (read)
       :to-graph users
       :for-allowed-group "public")

(grant (read write)
       :to-graph public
       :for-allowed-group "public")

;; example:

;; (supply-allowed-group "company"
;;   :query "PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>
;;           SELECT DISTINCT ?uuid WHERE {
;;             <SESSION_ID ext:belongsToCompany/mu:uuid ?uuid
;;           }"
;;   :parameters ("uuid"))

;; (grant (read write)
;;        :to company
;;        :for "company")
