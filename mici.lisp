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
  ;(setf lparallel:*kernel* (lparallel:make-kernel threads :name "custom-kernel"))
  (cl-mpm/utils::set-workers threads)
  (format t "Thread count ~D~%" threads))

(defparameter *name* (if (uiop:getenv "NAME") (uiop:getenv "NAME") "UNNAMED"))
(defparameter *ref* (parse-float:parse-float (if (uiop:getenv "REFINE") (uiop:getenv "REFINE") "1.0")))
(defparameter *height* (parse-float:parse-float (if (uiop:getenv "HEIGHT") (uiop:getenv "HEIGHT") "400")))
(defparameter *floatation* (parse-float:parse-float (if (uiop:getenv "FLOATATION") (uiop:getenv "FLOATATION") "0.9")))
(defparameter *slope* (let ((env (uiop:getenv "SLOPE"))) (parse-float:parse-float (if env env "0.0"))))
(defparameter *enable-viscosity* (if (uiop:getenv "VISC") (string= (uiop:getenv "VISC") "TRUE") nil))
(format t "Running~%")

(defparameter *top-dir* (merge-pathnames "/nobackup/rmvn14/thesis/mici/"))
(defparameter *delay-time* 1d6)
(defparameter *delay-exponent* 2d0)
(defparameter *angle* 40d0)
(defparameter *angle-r* 10d0)
(defparameter *angle-psi* 5d0)
(defparameter *rc* 0d0)
(defparameter *gf* 10000d0)
(defparameter *length-scaler* 0.5d0)
(defparameter *enable-plastic-damage* nil)
(defparameter *pd-oversize* 1d-3)

(defun damage-refinement-criteria (sim mesh c)
  (let ((damage 0d0)
        (damage-ybar 0d0))
    (cl-mpm/damage::iterate-over-point-neighbour-mps
     (aref (cl-mpm::sim-mesh-list sim) 0)
     (cl-mpm/mesh::cell-centroid c)
     ;; (* 2 *length-scale*)
     (cl-mpm/mesh::cell-h c)
     (lambda (mesh mp dist)
       (declare (ignore mesh dist))
       (with-accessors ((d-ybar cl-mpm/particle::mp-damage-ybar)
                        (d cl-mpm/particle::mp-damage)
                        (initiation-stress cl-mpm/particle::mp-initiation-stress))
           mp
         (declare (double-float damage-ybar initiation-stress damage))
         (setf damage-ybar (max (* ;; (- 1d0 damage)
                                   (/ d-ybar initiation-stress)) damage-ybar))
         (setf damage (max d damage))
         )))
    (case (cl-mpm/dynamic-relaxation::cell-mesh-index c)
      (0  (or (> damage-ybar 2d0)
              (> damage 0.20d0)))
      (1  (> damage 0.55d0))
      (2  (> damage 0.85d0))
      (3  (> damage 0.95d0))
      (t nil))
    ))


(let* ((density 918d0)
       (dt 1d3)
       (water-density 1028d0)
       (height *height*)
       (water-damping 0d0)
       (flotation *floatation*))
  (let* ((mps 4)
         (output-dir (merge-pathnames  (format nil "./output-~A-~D-~f-~f/" *name* *ref* height flotation) *top-dir*)))
    (format t "Outputting to ~A~%" output-dir)
    (format t "Problem ~f ~f~%" height flotation)
    (let* ((explicit-dt-scale 0.5d0)
           (ice-aspect 6d0)
           )
      (setup :refine *ref*
             :multigrid-refines 1
             :friction 0.5d0
             :bench-length 0d0;(* 1d0 height)
             :ice-height height
             :mps mps
             :hydro-static nil
             :cryo-static t
             :melange nil
             :aspect ice-aspect
             :slope *slope*
             :floatation-ratio flotation
             ;:use-penalty nil
             ;:stick-base t 
             )
      (cl-mpm::domain-sort-mps *sim*)
      (when (typep *sim* 'cl-mpm/dynamic-relaxation::mpm-sim-octree)
          (setf (cl-mpm/dynamic-relaxation::sim-intra-mesh-aggregation *sim*) t)
          (setf (cl-mpm/dynamic-relaxation::sim-octree-refinement-criteria *sim*)
            (lambda (sim mesh c)
              (or
               (and
                (= (cl-mpm/dynamic-relaxation::cell-mesh-index c) 0)
                (> (cl-mpm/utils::varef (cl-mpm/mesh::cell-centroid c) 0)
                   (* (- ice-aspect 1.5) height))
                (< (cl-mpm/utils::varef (cl-mpm/mesh::cell-centroid c) 0)
                   (* (+ 0.5d0 ice-aspect) height))
                (> (cl-mpm/utils::varef (cl-mpm/mesh::cell-centroid c) 1)
                   (+ (* 2 (cl-mpm/mesh::mesh-resolution (cl-mpm:sim-mesh *sim*)))
                      (* height 0.9d0 flotation)))
                )
               (damage-refinement-criteria sim mesh c)
               )
              )))

      
      (plot-domain)

      (setf (cl-mpm/damage::sim-enable-ekl *sim*) nil)
      (setf (cl-mpm/damage::sim-enable-length-localisation *sim*) t)
      (setf (cl-mpm::sim-allow-mp-split *sim*) t
            (cl-mpm::sim-max-split-depth *sim*) 4)

      (setf (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) 0d0)
      (setf (cl-mpm/aggregate::sim-enable-aggregate *sim*)  t
            (cl-mpm::sim-ghost-factor *sim*) nil)
      (setf lparallel:*debug-tasks-p* nil)
      (setf (cl-mpm::sim-allow-mp-damage-removal *sim*) nil)
      (setf (cl-mpm::sim-mp-damage-removal-instant *sim*) nil)
      (setf (cl-mpm:sim-settings *sim*)
            (list :OCEAN-HEIGHT *water-height*
                  :EXPLICIT-DT-SCALE explicit-dt-scale
                  :EKL  (cl-mpm/damage::sim-enable-ekl *sim*)
                  :LENGTH-LOCALISATION  (cl-mpm/damage::sim-enable-length-localisation *sim*)
                  :PLASTIC-DAMAGE-DRIVING *enable-plastic-damage* 
                  :PLASTIC-DAMAGE-OVERSIZE *pd-oversize*
                  :DELAY-TIME *delay-time*
                  :DELAY-EXP *delay-exponent*
                  :ANGLE *angle*
                  :ANGLE-R *angle-r*
                  :ANGLE-PSI *angle-psi*
                  :WATER-DAMPING water-damping
                  :R-C *rc*
                  :GF *gf*
                  :LENGTH-SCALER *length-scaler*))
      (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-15)
      (let ((step 0))
        (cl-mpm/dynamic-relaxation::run-multi-stage
         *sim*
         :output-dir output-dir
         :dt dt
         :total-time 1d8
         :dt-scale 0.9d0
         :damping-factor (sqrt 2d0)
         :conv-criteria 1d-6
         :conv-load-steps 1
         :min-adaptive-steps -12
         :max-adaptive-steps 14
         :adaption-constant 4
         :max-damage-inc 0.6d0
         :substeps 10
         :save-vtk-loadstep t
         :save-vtk-dr nil
         :enable-plastic t
         :enable-damage t
         :plotter (lambda (sim))
         :explicit-conv-criteria 1d-3
         :elastic-dt-margin 1d3
         :explicit-mass-scaling nil
         :explicit-dt-scale 0.5d0
         :explicit-damping-factor 1d-3
         :explicit-dynamic-solver 'cl-mpm/dynamic-relaxation::mpm-sim-octree-damage-usf

         ;:explicit-dt-scale explicit-dt-scale
         ;:explicit-damping-factor 1d-3
         ;:explicit-dynamic-solver 'cl-mpm/damage::mpm-sim-agg-damage

         ;:explicit-damping-factor 1d-2
         ;:explicit-dt-scale 10d0
         ;:explicit-dynamic-solver 'cl-mpm/dynamic-relaxation::mpm-sim-implict-dynamic 
         ;:explicit-dynamic-solver 'cl-mpm/dynamic-relaxation::mpm-sim-octree-implicit-dynamic
         :post-conv-step (lambda (sim)
                           (setf (cl-mpm/buoyancy::bc-enable *bc-erode*) nil))
         :setup-quasi-static
         (lambda (sim)
           (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-15)
           (setf
            (cl-mpm/aggregate::sim-enable-aggregate sim) t
            (cl-mpm::sim-ghost-factor sim) nil
            ;(cl-mpm/aggregate::sim-enable-aggregate sim) nil
            ;(cl-mpm::sim-ghost-factor sim) (* 1d9 1d-2)
            (cl-mpm::sim-velocity-algorithm sim) :QUASI-STATIC
            (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) 0d0))
         :setup-dynamic
         (lambda (sim)
           (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-15)
           (setf 
             (cl-mpm/damage::sim-damage-delocal-counter-max sim) 10
             (cl-mpm/aggregate::sim-enable-aggregate sim) t
             (cl-mpm::sim-ghost-factor sim) nil
             ;(cl-mpm/aggregate::sim-enable-aggregate sim) nil
             ;(cl-mpm::sim-ghost-factor sim) (* 918d0 1d-9) 
             (cl-mpm::sim-velocity-algorithm sim) :TBLEND
             ;(cl-mpm::sim-velocity-algorithm sim) :TFLIP
             ;(cl-mpm::sim-velocity-algorithm sim) :FLIP
             (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) water-damping)))))))
