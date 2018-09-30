;; -*- mode:lisp;coding:utf-8 -*-
(in-package "DEMO-CGI")

(declaim (declaration stepper))

(defparameter *external-format*
  #+clisp (ext:make-encoding :charset charset:utf-8 :line-terminator :dos)
  #-clisp :utf-8)

(defun error-file-pathname ()  #P"/tmp/demo-cgi.errors")
(defun trace-file-pathname ()  #P"/tmp/demo-cgi.traces")


(defun print-backtrace (stream)
  #-(or ccl sbcl clisp) (declare (ignore stream))
  #+clisp (system::print-backtrace :out stream)
  #+(or ccl sbcl) (format stream "~&~80,,,'-<~>~&~{~A~%~}~80,,,'-<~>~&"
                          #+sbcl (sb-debug:backtrace-as-list)
                          #+ccl (ccl::backtrace-as-list)))

(defun date (&optional (date (get-universal-time)))
  (format nil "~{~5*~4,'0D-~2:*~2,'0D-~2:*~2,'0D ~2:*~2,'0D:~2:*~2,'0D:~2:*~2,'0D~8*~}"
          (multiple-value-list (decode-universal-time date))))

(defun bare-stream (stream &key (direction :output))
  "
RETURN: A stream or a list of streams that are not compound streams
        (and therefore usable by #+clisp SOCKET:SOCKET-STATUS).
"
  (etypecase stream

    #-mocl
    (echo-stream
     (ecase direction
       (:output (bare-stream (echo-stream-output-stream stream)
                             :direction direction))
       (:input  (bare-stream (echo-stream-input-stream  stream)
                             :direction direction))))
    #-mocl
    (two-way-stream
     (ecase direction
       (:output (bare-stream (two-way-stream-output-stream stream)
                             :direction direction))
       (:input  (bare-stream (two-way-stream-input-stream stream)
                             :direction direction))))

    #-mocl
    (synonym-stream
     (bare-stream (symbol-value (synonym-stream-symbol stream))
                  :direction direction))

    #-mocl
    (broadcast-stream
     (remove-if-not
      (lambda (stream)
        (ecase direction
          (:output (output-stream-p stream))
          (:input  (input-stream-p  stream))))
      (mapcar (lambda (stream) (bare-stream stream :direction direction))
              (broadcast-stream-streams stream))))
    (stream stream)))

(defmacro reporting-errors (&body body)
  (let ((vhandler (gensym)))
    `(block ,vhandler
       (handler-bind ((error (lambda (err)
                               (declare (ignorable err))
                               (declare (stepper disable))
                               (format *trace-output* "Found error ~A~%" err)
                               (let ((*print-length* nil)
                                     (*print-level*  nil)
                                     (*print-circle* t)
                                     (*print-pretty* nil)
                                     (*print-case*   :downcase))
                                 (with-open-file (errf (error-file-pathname)
                                                       :direction :output
                                                       :external-format *external-format*
                                                       :if-exists :append
                                                       :if-does-not-exist :create)
                                   (let ((errs (if (eq (bare-stream *trace-output*)
                                                       (bare-stream *error-output*))
                                                   (make-broadcast-stream errf *error-output*)
                                                   (make-broadcast-stream errf *error-output* *trace-output*))))
                                     (format errs "~%~A~2%" (date))
                                     (print-backtrace errs)
                                     (format errs "~%ERROR while ~S:~%~A~2%"
                                             ',(if (= 1 (length body)) body `(progn ,@body))
                                             err)
                                     (finish-output errs))))
                               #+debug-on-error (invoke-debugger err)
                               (return-from ,vhandler nil))))
         ,@body))))

(defun lsencod ()
  (format t "~%~{~32A ~A~%~}~%"
          (list
           'custom:*default-file-encoding* custom:*default-file-encoding*
           #+ffi 'custom:*foreign-encoding* #+ffi custom:*foreign-encoding*
           'custom:*misc-encoding*         custom:*misc-encoding*
           'custom:*pathname-encoding*     custom:*pathname-encoding*
           'custom:*terminal-encoding*     custom:*terminal-encoding*
           'system::*http-encoding*        system::*http-encoding*
           '*external-format*              *external-format*))
  (values))

(defun process-query (arguments query url)
  (format t "Content-Type: text/plain;charset=utf-8~%")
  (format t "~%")
  (format t "~2%Arguments:~%----------~2%")
  (format t "~{~S~^~%~}~%" arguments)
  (format t "~2%Query:~%----------~2%")
  (format t "Got query: ~S~%at url: ~S~%" query url)
  (format t "~2%Encodings:~%----------~2%")
  (lsencod)
  (format t "~2%Environment:~%------------~2%")
  (format t "~{~S~%~}" (sort (copy-list (ext:getenv)) (function string<) :key (function car)))
  (format t "~%")
  (format t "~2%Some text:~%----------")
  (format t "
Hao Wang, logicien americain.

L'algorithme en  question  a  été  publié  en  1960  dans l'IBM Journal,
article intitule \"Toward  Mechanical Mathematics\", avec des variantes et
une  extension au calcul  des  prédicats.  Il  s'agit  ici  du  \"premier
programme\" de Wang, système \"P\".

L'article a été écrit en 1958, et les expériences effectuées sur IBM 704
­ machine à lampes, 32 k  mots  de 36 bits, celle­là même qui vit naître
LISP à la même époque. Le programme  a  été écrit en assembleur (Fortran
existait, mais il ne s'était pas encore imposé)  et  l'auteur estime que
\"there is very little in the program that is not straightforward\".

Il observe que les preuves engendrées sont \"essentiellement des arbres\",
et  annonce  que  la  machine  a  démontré 220 théorèmes du  calcul  des
propositions  (tautologies)  en  3  minutes. Il en tire argument pour la
supériorité  d'une  approche  algorithmique  par  rapport à une approche
heuristique comme celle du \"Logic Theorist\" de Newell, Shaw et  Simon (à
partir de 1956 sur la machine JOHNNIAC de la Rand Corporation): un débat
qui dure encore...

Cet  algorithme  a  été popularisé par J. McCarthy, comme exemple­fanion
d'application  de LISP. Il figure dans le manuel de la première  version
de  LISP  (LISP  1,  sur IBM 704 justement, le manuel est daté  de  Mars
1960), et il a été repris dans le célèbre \"LISP 1.5 Programmer's Manual\"
publié en 1962 par MIT Press, un des maîtres­livres de l'Informatique.
"))

(defun main (&optional (arguments *args*))
  (reporting-errors
   (with-open-file (*trace-output* (trace-file-pathname)
                                   :direction :output
                                   :external-format *external-format*
                                   :if-exists :append
                                   :if-does-not-exist :create)
     (setf (stream-external-format *standard-output*) *external-format*)
     (let* ((scheme (getenv "REQUEST_SCHEME"))
            (host   (getenv "HTTP_HOST"))
            (port   (getenv "SERVER_PORT"))
            (uri    (getenv "REQUEST_URI"))
            (query  (getenv "QUERY_STRING"))
            (url    (format nil "~A://~A:~A~A" scheme host port uri)))
       (process-query arguments query url))
     (finish-output)
     (exit 0))))


