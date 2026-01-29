(sb-ext:restrict-compiler-policy 'speed 3 3)
(sb-ext:restrict-compiler-policy 'debug 0 0)
(sb-ext:restrict-compiler-policy 'safety 0 0)
(setf *block-compile-default* t)
;(sb-ext:restrict-compiler-policy 'speed 0 0)
;(sb-ext:restrict-compiler-policy 'debug 3 3)
;(sb-ext:restrict-compiler-policy 'safety 3 3)
;(setf *block-compile-default* t)
(ql:quickload :local-time)
(ql:quickload :cl-mpm/examples/ice-buoyancy)
(ql:quickload :parse-float)
(in-package :cl-mpm/examples/ice-buoyancy)
(setf cl-mpm/settings::*optimise-setting* cl-mpm/settings::*optimise-speed*)
;(setf cl-mpm/settings::*optimise-setting* cl-mpm/settings::*optimise-debug*)
(defun main (&optional args)
	(load "mici.lisp"))

(sb-ext:save-lisp-and-die
   "worker"
    :executable t
    :toplevel #'main
    :compression t
    :save-runtime-options t)
(uiop:quit)
