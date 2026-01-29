(in-package :cl-mpm/examples/ice-buoyancy)
(defun plot (sim)
  ;No plotting
  (format t "~A ~%" (local-time:now))
  )
(defun plot-domain ()
  ;No plotting
  (format t "~A ~%" (local-time:now))
  )
(setf lparallel:*debug-tasks-p* nil)

(let ((threads (parse-integer (if (uiop:getenv "OMP_NUM_THREADS") (uiop:getenv "OMP_NUM_THREADS") "16"))))
  (setf lparallel:*kernel* (lparallel:make-kernel threads :name "custom-kernel"))
  (format t "Thread count ~D~%" threads))

(defparameter *name* (if (uiop:getenv "NAME") (uiop:getenv "NAME") "UNNAMED"))
(defparameter *ref* (parse-float:parse-float (if (uiop:getenv "REFINE") (uiop:getenv "REFINE") "1")))
(defparameter *height* (parse-float:parse-float (if (uiop:getenv "HEIGHT") (uiop:getenv "HEIGHT") "400")))
(defparameter *floatation* (parse-float:parse-float (if (uiop:getenv "FLOATATION") (uiop:getenv "FLOATATION") "0.9")))
(format t "Running~%")

(defparameter *top-dir* (merge-pathnames "/nobackup/rmvn14/thesis/mici/"))

(let* ((density 918d0)
       (water-density 1028d0)
       (height *height*)
       (flotation *floatation*))
  (let* ((mps 2)
         (output-dir (merge-pathnames  (format nil "./output-~A-~f-~f/" *name* height flotation) *top-dir*)))
    (format t "Outputting to ~A~%" output-dir)
    (format t "Problem ~f ~f~%" height flotation)
    (let* ((mps 2))
      (setup :refine 0.5
             :friction 0.8d0
             :bench-length (* 0d0 height)
             :ice-height height
             :mps mps
             :hydro-static nil
             :cryo-static t
             :melange nil
             :aspect 2d0
             :slope 0d0
             :floatation-ratio flotation)
      (plot-domain)
      (setf (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) 0d0)
      (setf (cl-mpm/damage::sim-enable-length-localisation *sim*) t)
      (setf (cl-mpm/aggregate::sim-enable-aggregate *sim*) nil (cl-mpm::sim-ghost-factor *sim*) nil)
      (setf lparallel:*debug-tasks-p* nil)
      (setf (cl-mpm::sim-allow-mp-damage-removal *sim*) nil)
      (setf (cl-mpm::sim-mp-damage-removal-instant *sim*) nil)
      (setf (cl-mpm/damage::sim-enable-length-localisation *sim*) t)
      (setf (cl-mpm:sim-enable-damage *sim*) nil)
      (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-15)
      (let ((step 0))
        (cl-mpm/dynamic-relaxation::run-multi-stage
         *sim*
         :output-dir output-dir
         :dt dt
         :dt-scale 1d0
         :damping-factor 1d0
         :conv-criteria 1d-3
         :conv-load-steps 1
         :min-adaptive-steps -8
         :max-adaptive-steps 14
         :substeps 20
         :steps 1000
         :enable-plastic t
         :enable-damage t
         :plotter (lambda (sim))
         :explicit-dt-scale 0.49d0
         :explicit-damping-factor 1d-3
         :explicit-dynamic-solver 'cl-mpm/damage::mpm-sim-agg-damage
         ;; :explicit-damping-factor 0d-4
         ;; :explicit-dt-scale 1d0
         ;; :explicit-dynamic-solver 'cl-mpm/dynamic-relaxation::mpm-sim-implict-dynamic
         :post-conv-step (lambda (sim)
                           (setf (cl-mpm/buoyancy::bc-enable *bc-erode*) nil))
         :setup-quasi-static
         (lambda (sim)
           (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-15)
           (setf
            (cl-mpm/aggregate::sim-enable-aggregate sim) t
            (cl-mpm::sim-velocity-algorithm sim) :QUASI-STATIC
            (cl-mpm::sim-ghost-factor sim) nil
            (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) 0d0))
         :setup-dynamic
         (lambda (sim)
           (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-15)
           (setf (cl-mpm/aggregate::sim-enable-aggregate sim) t
                 (cl-mpm::sim-velocity-algorithm sim) :BLEND
                 (cl-mpm::sim-ghost-factor sim) nil ;(* 1d9 1d-4)
                 (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) 2d0)))))))
