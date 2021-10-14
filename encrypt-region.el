;; Copyright © 2021, Carlton Shepherd
;; Author: Carlton Shepherd (https://cs.gl)
;; Version: 0.1
;; Created: 14 October 2021
;; Keywords: encryption
;; License: GPLv3
;; Homepage: https://github.com/cgshep/encrypt-region
;;
;; Notes: This package enables the encryption and decryption of regions. Authenticated encryption is used by default using ChaCha20-Poly1305 from GnuTLS.
;;
;; This file is not part of GNU Emacs.

(defgroup encrypt-region nil
  "Encrypt region group."
  :group 'text)

(defcustom encrypt-region--key "key"
  "Define key for encrypting regions."
  :type 'string
  :group 'encrypt-region)

(defcustom encrypt-region--buf-name "name"
  "Define name for outputting encrypted regions."
  :type 'string
  :group 'encrypt-region)

(defun encrypt-region--pad (input length)
  "Pad string to a given length"
    ;;; Thanks to auth-source.el https://github.com/emacs-mirror/emacs/blob/master/lisp/auth-source.el
  (let ((p (- length (mod (length input) length))))
    (concat input (make-string p p))))

(defun encrypt-region--unpad (string)
  "Remove padding from string."
  ;;; Thanks to auth-source.el https://github.com/emacs-mirror/emacs/blob/master/lisp/auth-source.el
  (substring string 0 (- (length string)
			 (aref string (1- (length string))))))

(defun decrypt-region (start end)
  (interactive "r")
  (let ((ctext-str (split-string (buffer-substring start end) "#####")))
    (with-output-to-temp-buffer encrypt-region--buf-name
      (print1 (encrypt-region--unpad
	      (decode-coding-string
	       (gnutls-symmetric-decrypt "CHACHA20-POLY1305"
					 (copy-sequence encrypt-region--key)
					 (base64-decode-string (cadr ctext-str)) ; Decode the IV
					 (base64-decode-string (car ctext-str))) ; Decode the ciphertext
	       'utf-8)))
      (switch-to-buffer encrypt-region--buf-name))))
     
(defun encrypt-region (start end)
  "Encrypts a region and ouputs its base64 encoding in a new buffer."
  (interactive "r")
  (with-output-to-temp-buffer encrypt-region--buf-name
    (princ (mapconcat
	    #'base64-encode-string
	    (gnutls-symmetric-encrypt
	     "CHACHA20-POLY1305"
	     (copy-sequence encrypt-region--key)
	     (list 'iv-auto 12)
	     (encrypt-region--pad
	      (encode-coding-string (buffer-substring start end) 'utf-8)
	      64)
	     "") "###"))
    (switch-to-buffer encrypt-region--buf-name)))

(provide 'encrypt-region)
