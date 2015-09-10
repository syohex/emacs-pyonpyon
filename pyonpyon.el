;;; pyonpyon.el --- pyonpyon

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-pyonpyon
;; Version: 0.01

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'cl-lib)

(defcustom pyonpyon nil
  "Emacs ga pyonpyon surunja-"
  :group 'frame)

(defcustom pyonpyon-gravity (* 0.017 2) ;;2.4
  "Gravity")

(defvar pyonpyon--minimum-y
  (cond ((equal (getenv "XDG_CURRENT_DESKTOP") "XFCE") 50)
        (t 0)))

(defvar pyonpyon--timer nil)

(defvar pyonpyon--max-x 0)
(defvar pyonpyon--max-y 0)
(defvar pyonpyon--xpos 0)
(defvar pyonpyon--ypos 0)
(defvar pyonpyon--x-velocity 0)
(defvar pyonpyon--y-velocity 0)
(defvar pyonpyon--unit-v 0)

(defun pyonpyon--display-size-x-window ()
  (with-temp-buffer
    (process-file "xdpyinfo" nil t)
    (goto-char (point-min))
    (when (re-search-forward "dimensions:\\s-+\\([0-9]+\\)x\\([0-9]+\\)" nil t)
      (cons (string-to-number (match-string-no-properties 1))
            (string-to-number (match-string-no-properties 2))))))

(defun pyonpyon--display-size-darwin ()
  (with-temp-buffer
    (process-file "system_profiler" nil t nil "SPDisplaysDataType")
    (goto-char (point-min))
    (when (re-search-forward "Resolution:\\s-+\\([0-9]+\\) x \\([0-9]+\\)" nil t)
      (cons (string-to-number (match-string-no-properties 1))
            (string-to-number (match-string-no-properties 2))))))

(defun pyonpyon--display-size-windows ()
  (with-temp-buffer
    (process-file "wmic" nil t nil "desktopmonitor" "get" "screenheight," "screenwidth")
    (goto-char (point-min))
    (forward-line 1)
    (when (re-search-forward "\\([0-9]+\\)\\s-+\\([0-9]+\\)" nil t)
      (cons (string-to-number (match-string-no-properties 2))
            (string-to-number (match-string-no-properties 1))))))

(defun pyonpyon--display-size ()
  (cl-case system-type
    (gnu/linux (pyonpyon--display-size-x-window))
    (darwin (pyonpyon--display-size-darwin))
    (windows-nt (pyonpyon--display-size-windows))))

(defun pyonpyon--update-xpos ()
  (let ((next (+ pyonpyon--xpos pyonpyon--x-velocity)))
    (cond ((< next 0)
           (setq pyonpyon--xpos 0
                 pyonpyon--x-velocity (- pyonpyon--x-velocity)))
          ((> next (- pyonpyon--max-x (frame-pixel-width)))
           (setq pyonpyon--xpos (- pyonpyon--max-x (frame-pixel-width))
                 pyonpyon--x-velocity (- pyonpyon--x-velocity)))
          (t
           (setq pyonpyon--xpos next)))))

(defun pyonpyon--update-ypos ()
  (setq pyonpyon--ypos (* pyonpyon--max-y (abs (sin (* pyonpyon--y-velocity 4)))))
  (cl-incf pyonpyon--y-velocity pyonpyon-gravity))

(defun pyonpyon--move-frame ()
  (pyonpyon--update-xpos)
  (pyonpyon--update-ypos)
  (set-frame-position (window-frame)
                      (floor pyonpyon--xpos)
                      (floor (- pyonpyon--max-y pyonpyon--ypos (- pyonpyon--minimum-y)))))

(defun pyonpyon--init ()
  (let* ((max-xy (pyonpyon--display-size))
         (max-x (car max-xy))
         (max-y (cdr max-xy))
         (unit-h (/ max-x 133.0))
         (unit-v (sqrt (* max-y pyonpyon-gravity 2))))
    (setq pyonpyon--max-x max-x
          pyonpyon--max-y (- max-y (frame-pixel-height) 50)
          pyonpyon--x-velocity unit-h
          pyonpyon--y-velocity unit-v
          pyonpyon--unit-v unit-v)
    (setq pyonpyon--xpos 0 pyonpyon--ypos 300)))

;;;###autoload
(defun pyonpyon ()
  (interactive)
  (pyonpyon--init)
  (when pyonpyon--timer
    (pyonpyon-stop))
  (setq pyonpyon--timer (run-with-timer 0 0.1 #'pyonpyon--move-frame)))

;;;###autoload
(defun pyonpyon-stop ()
  (interactive)
  (cancel-timer pyonpyon--timer)
  (setq pyonpyon--timer nil))

(provide 'pyonpyon)

;;; pyonpyon.el ends here
