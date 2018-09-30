
(in-package "COMMON-LISP-USER")

(load #P"~/quicklisp/setup.lisp")

(push (make-pathname :name nil :type nil :version nil
                     :defaults *load-pathname*)
      asdf:*central-registry*)

(ql:quickload "demo-cgi")

(defparameter *executable-pathname*  (merge-pathnames #P"demo.cgi" *load-pathname*))
(defparameter *main-function*        'demo-cgi:main)
(defparameter *documentation*        "Demo CGI")

#+clisp
(ext:saveinitmem *executable-pathname*
                 :executable t
                 :start-package "COMMON-LISP-USER"
                 :init-function *main-function*
                 :documentation *documentation*
                 :quiet t
                 :verbose nil
                 :norc t)

;; on other implementations, we use trivial-dump-core to save the image:
#-clisp (ql:quickload "trivial-dump-core")
#-clisp (trivial-dump-core:save-executable *executable-pathname* *main-function*)

