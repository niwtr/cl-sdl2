(in-package #:sdl2)

;;;; TODO: This is missing the interface out of SDL_rect.h
;;;; SDL_EnclosePoints()


(defun make-point (x y)
  "Return an SDL_Point filled in with the arguments. It will be garbage collected as needed."
  (c-let ((point sdl2-ffi:sdl-point))
    (setf (point :x) x
          (point :y) y)
    point))

(define-struct-accessors (point sdl2-ffi:sdl-point)
  :x :y)

(defmacro c-point ((wrapper-var) &body body)
  `(c-let ((,wrapper-var sdl2-ffi:sdl-point :from ,wrapper-var))
     ,@body))

(defmacro c-points ((&rest wrappers) &body body)
  (if wrappers
      `(c-point (,(car wrappers))
         (c-points (,@(cdr wrappers)) ,@body))
      `(progn ,@body)))

(defmethod print-object ((point sdl2-ffi:sdl-point) stream)
  (c-point (point)
    (print-unreadable-object (point stream :type t :identity t)
      (format stream "x ~A y ~A" (point :x) (point :y)))))

(defun copy-point (point)
  "Allocate and return a new SDL_Point and make its slots be equal to the passed in SDL_Point."
  (c-point (point)
    (make-point (point :x) (point :y))))

(defun copy-into-point (dest-point src-point)
  "Copy the information from the SDL_Point src-point into the SDL_Point dest-point. Return the
dest-point."
  (c-points (dest-point src-point)
    (setf (dest-point :x) (src-point :x)
          (dest-point :y) (src-point :y)))
  dest-point)

(defun free-point (point)
  "Specifically free the SDL_Point structure which will do the right thing with respect to the
garbage collector. This is not required, but may make garbage collection performance better if used
in tight SDL_Point allocating loops."
  (foreign-free (ptr point))
  (autowrap:invalidate point))

;; used as a helper for with-points
(defmacro %with-point ((binding) &body body)
  (cond
    ((symbolp binding)
     `(let ((,binding (make-point 0 0)))
        (unwind-protect (progn ,@body)
	  (free-point ,binding))))
    ((= (length binding) 3)
     `(let ((,(first binding) (make-point ,@(cdr binding))))
	(unwind-protect (progn ,@body)
	  (free-point ,(first binding)))))
    (t
     (error "with-point: Must have a binding of either a symbol or a symbol and 2 forms which are ~
x y of a point"))))

(defmacro with-points (bindings &body body)
  "A LET-like convenient bindings facility for SDL_point structures. Raw symbols are bound
to (make-point 0 0).

  Example:

  (let ((a 1) (b 2))
    (with-points (foo
                  (qux 5 10)
                  (bar (1+ a) b)
       (list foo qux bar))))

  -> (#<SDL-FFI:SDL-POINT x 0 y 0>
      #<SDL-FFI:SDL-POINT x 5 y 10>
      #<SDL-FFI:SDL-POINT x 2 y 2>)"
  (if bindings
      `(%with-point (,(car bindings))
         (with-points ,(cdr bindings) ,@body))
      `(progn ,@body)))

(defun points* (&rest points)
  "Return a pointer to SDL_Point and the number of elements in it."
  (let ((num-points (length points)))
    (c-let ((c-points sdl2-ffi:sdl-point :count num-points))
      (loop :for i :from 0
            :for point :in points
            :do (copy-into-point (c-points i) point))
      (values (c-points &) num-points))))

(defmacro c-rect ((r) &body body)
  `(c-let ((,r sdl2-ffi:sdl-rect :from ,r))
     ,@body))

(defmacro c-rects ((&rest wrappers) &body body)
  (if wrappers
      `(c-rect (,(car wrappers))
         (c-rects (,@(cdr wrappers)) ,@body))
      `(progn ,@body)))

(defun make-rect (x y w h)
  "Allocate and return a new SDL_Rect filled in with the arguments. It
will be garbage collected as needed."
  (c-let ((rect sdl2-ffi:sdl-rect))
    (setf (rect :x) x
          (rect :y) y
          (rect :w) w
          (rect :h) h)
    rect))

(define-struct-accessors (rect sdl2-ffi:sdl-rect)
  :x :y (width :w) (height :h))

(defmethod print-object ((rect sdl2-ffi:sdl-rect) stream)
  (c-rect (rect)
    (print-unreadable-object (rect stream :type t :identity t)
      (format stream "x ~A y ~A w ~A h ~A" (rect :x) (rect :y) (rect :w) (rect :h)))))

(defun copy-rect (rect)
  "Allocate and return a new SDL_Rect and make its slots be equal to the passed in SDL_Rect."
  (c-rect (rect)
    (make-rect (rect :x) (rect :y) (rect :w) (rect :h))))

(defun copy-into-rect (dest-rect src-rect)
  "Copy the information from the SDL_Rect src-rect into the SDL_Rect dest-rect. Return the
dest-rect."
  (c-rects (dest-rect src-rect)
    (setf (dest-rect :x) (src-rect :x)
          (dest-rect :y) (src-rect :y)
          (dest-rect :w) (src-rect :w)
          (dest-rect :h) (src-rect :h)))
  dest-rect)

(defun free-rect (rect)
  "Specifically free the SDL_Rect structure which will do the right thing with respect to the
garbage collector. This is not required, but may make garbage collection performance better if used
in tight SDL_Rect allocating loops."
  (foreign-free (ptr rect))
  (autowrap:invalidate rect))

;; I hope trivial-garbage deals with these things correctly...

(defmacro let-rects (bindings &body body)
  (flet ((make-rect-list (bindings)
           (loop :for rect :in bindings :collect (list rect 'sdl2-ffi:sdl-rect))))
    `(c-let (,@(make-rect-list bindings))
       ,@body)))

;; used as a helper for with-rects
(defmacro %with-rect ((binding) &body body)
  (cond
    ((symbolp binding)
     `(let ((,binding (make-rect 0 0 0 0)))
        (unwind-protect (progn ,@body)
	  (free-rect ,binding))))
    ((= (length binding) 5)
     `(let ((,(first binding) (make-rect ,@(cdr binding))))
        (unwind-protect (progn ,@body)
	  (free-rect ,(first binding)))))
    (t
     (error "with-rect: Must have a binding of either a symbol or a symbol and 4 forms which are ~
x y w h of a rectangle"))))

(defmacro with-rects (bindings &body body)
  "A LET-like convenient bindings facility for SDL_Rect structures. Raw symbols are bound
to (make-rect 0 0 0 0).

  Example:

  (let ((a 1) (b 2) (c 3) (d 4))
    (with-rects (foo
                 (qux 5 10 15 20)
                 (bar (1+ a) b c (* d 10)))
       (list foo qux bar)))

  -> (#<SDL-FFI:SDL-RECT x 0 y 0 w 0 z 0>
      #<SDL-FFI:SDL-RECT x 5 y 10 w 15 h 20>
      #<SDL-FFI:SDL-RECT x 2 y 2 w 3 d 40>)"
  (if (null bindings)
      `(progn ,@body)
      `(%with-rect (,(car bindings))
         (with-rects ,(cdr bindings) ,@body))))

(defun rects* (&rest rects)
  "Return a pointer to SDL_Rect and the number of elements in it."
  (let ((num-rects (length rects)))
    (c-let ((c-rects sdl2-ffi:sdl-rect :count num-rects))
      (loop :for i :from 0
            :for rect :in rects
            :do (copy-into-rect (c-rects i) rect))
      (values (c-rects &) num-rects))))

;;; The implementation of the SDL_rect.h methods.

(defun rect-empty (&rest rects)
  "Return T if the rectangle has no width or height."
  (every (lambda (rect)
           (c-rect (rect)
            (and (not (null-pointer-p (ptr rect)))
                 (or (<= (rect :w) 0)
                     (<= (rect :h) 0)))))
         rects))

(defun %rect-equal (a b)
  "Return T if the two rectanges are valid and the slots are equal"
  (c-rects (a b)
    (and (= (a :x) (b :x))
         (= (a :y) (b :y))
         (= (a :w) (b :w))
         (= (a :h) (b :h)))))

(defun rect-equals (first-rect &rest rects)
  "Return T if the passed in SDL_Rect structures are valid and all slots are equal to each other."
  (dolist (rect rects)
    (when (not (%rect-equal first-rect rect))
      (return-from rect-equals nil)))
  t)

(defun has-intersect (first-rect &rest rects)
  "Return T if every SDL_Rect structure intersects every other SDL_Rect structure."
  (loop :for (a b) :in (unique-pairs `(,first-rect ,@rects))
        :do (unless (sdl-true-p (sdl-has-intersection a b))
              (return-from has-intersect nil)))
  t)

(defun intersect-rect (first-rect &rest rects)
  "Return two values. The first one is T if the intersection of ALL rectangles results in a
non-empty intersection. The second value is the SDL_Rect of the intersection rectangle. If an empty
intersection is discovered, then NIL and an empty rectangle at the origin is returned. The second
value is always a newly allocated SDL_Rect structure."
  (let ((empty (make-rect 0 0 0 0))
        (intersect (copy-rect first-rect)))
    (dolist (rect rects)
      (unless (sdl-true-p (sdl-intersect-rect rect intersect intersect))
        (return-from intersect-rect (values nil empty))))
    (values t intersect)))

(defun intersect-rect-and-line (rect x1 y1 x2 y2)
  "Returns five values where the first value is T if the coordinates of the line
intersect RECT. The remaining returned values represent the starting and ending
coordinates of the line clipped to the boundary of the rectangle."
  (c-with ((x1pos :int)
	   (y1pos :int)
	   (x2pos :int)
	   (y2pos :int))

    (setf x1pos x1
	  y1pos y1
	  x2pos x2
	  y2pos y2)

    (let ((intersected (sdl-true-p (sdl-intersect-rect-and-line rect (x1pos &) (y1pos &) (x2pos &) (y2pos &)))))
      (values intersected x1pos y1pos x2pos y2pos))))

(defun union-rect (first-rect &rest rects)
  "Calculate and return the union of all rectangles passed in. The result will be one large
rectangle as a newly allocated SDL_rect in which all others fit perfectly."
  (let ((union-rect (copy-rect first-rect)))
    (dolist (rect rects)
      (sdl-union-rect rect union-rect union-rect))
    union-rect))
