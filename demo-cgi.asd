(asdf:defsystem "demo-cgi"
  :description "Demo CGI."
  :author "Pascal Bourguignon"
  :version "0.0.0"
  :license "AGPL3"
  :depends-on ("alexandria")
  :components ((:file "packages")
               (:file "demo-cgi" :depends-on ("packages")))
  #+asdf-unicode :encoding #+asdf-unicode :utf-8)
