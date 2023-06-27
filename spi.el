;;; spi.el --- A simple package installer for Emacs based on Git.
;;; -*- lexical-binding: t; -*-

;; Author: Finger Knight
;; Version: 0.1.0
;; Package-Requires: (Emacs)
;; Homepage: https://github.com/fingerknight/spi
;; Keywords: Package Emacs

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A simple package installer for Emacs based on Git.
;; No VC, no branch choosing, no special commit, just Git it and compile.
;; With small inspriation from https://bitbucket.org/zbelial/pie.

;;; Requirements:

;; Emacs 28.2

;;; Code:

(defgroup spi nil
  "Package installer for Emacs."
  :group 'package)

(defcustom spi-repo-directory (expand-file-name "spi/repo" user-emacs-directory)
  "The directory used to store packages' repositories."
  :type  'directory
  :group 'spi)

(defcustom spi-build-directory (expand-file-name "spi/build" user-emacs-directory)
  "The directory used to store built packages."
  :type  'directory
  :group 'spi)

(defun spi--all-pacakges ()
  "Return a list containing all packages."
  (mapcar #'intern (directory-files spi-repo-directory nil "[^.]")))

(defun spi-installed-p (pkg)
  "If packages is installed.
PKG should be a symbol."
  (file-exists-p (expand-file-name
                  (format "%s" pkg)
                  spi-repo-directory)))

(defun spi-install (pkg url)
  "Install pacakges by Git.
PKG should be a  symbol, and URL should be a string.

If PKG has already existed, then try to reinstall it."
  (let* ((pkg-name (symbol-name pkg))
         (dir (expand-file-name pkg-name spi-repo-directory)))
    (when (spi-installed-p pkg)
      (message "Package %s exists. Trying to reinstall." pkg-name)
      (spi-remove pkg))
    (message "Fetching %s..." pkg-name)
    (with-temp-buffer
      (if (= (call-process "git" nil t nil
                           "clone" url dir)
             0)
          (spi-build pkg)
        (message (buffer-string))))))

(defun spi--byte-compile-dest-file (filename)
  "Return the destination of compiled file."
  (expand-file-name 
   (file-name-with-extension
    (file-relative-name filename
                        spi-repo-directory)
    "elc")
   spi-build-directory))

(defun spi-build (pkg)
  "Build package. Compile all files with extension `.el',
except file's name starts with dot `.'.
PKG should be a symbol."
  (let* ((pkg-name (symbol-name pkg))
         (src (expand-file-name pkg-name spi-repo-directory))
         (dst (expand-file-name pkg-name spi-build-directory)))
    (when (file-directory-p dst)
      (delete-directory dst t))
    (if (not (spi-installed-p pkg))
        (message "No such package: %s" pkg-name)
      (copy-directory src dst t t)
      (dolist (file (directory-files-recursively dst "\\.el$"))
        (when (string= (file-name-extension file)
                       "el")
          (byte-compile-file file)))
      (add-to-list 'load-path dst))))

(defun spi-update (pkg)
  "Update single package.
PKG should be a symbol"
  (let* ((pkg-name (symbol-name pkg))
         (dir (expand-file-name pkg-name spi-repo-directory)))
    (if (not (spi-installed-p pkg))
        (message "No such package: %s" pkg-name)
      (message "Updating: %s..." pkg-name)
      (with-temp-buffer
        (let ((default-directory dir))
          (if (= (call-process "git" nil t nil
                               "pull")
                 0)
              (spi-build pkg)
            (message (buffer-string))))))))

(defun spi-update-all ()
  "Update all packages."
  (interactive)
  (dolist (pkg spi--all-pacakges)
    (spi-update pkg)))

(defun spi-remove (pkg)
  "Remove package.
PKG should be a symbol."
  (let* ((pkg-name (symbol-name pkg))
         (dirs (list (expand-file-name pkg-name spi-repo-directory)
                     (expand-file-name pkg-name spi-build-directory))))
    (message "Removing package: %s" pkg-name)
    (dolist (it dirs)
      (delete-directory it t))))


(provide 'spi)
;;; spi.el ends here
