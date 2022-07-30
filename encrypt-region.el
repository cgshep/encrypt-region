;; Copyright © 2021, Carlton Shepherd
;; Author: Carlton Shepherd (https://cs.gl)
;; Version: 0.2
;; Created: 14 October 2021
;; Modified: 30 July 2022
;; Keywords: encryption
;; License: GPLv3
;; Homepage: https://github.com/cgshep/encrypt-region
;;
;; Notes: This package allows the encryption and decryption of regions.
;;        Authenticated encryption is provided by ChaCha20-Poly1305 from GnuTLS.
;;
;; This file is not part of GNU Emacs.
;;
(defgroup encrypt-region nil
  "Encrypt region group."
  :group 'text)

(defcustom encrypt-region--key "key"
  "Define a 16-byte/32-hexchar key for encrypting regions."
  :type 'string
  :group 'encrypt-region)

(defcustom encrypt-region--encrypt-buf-name "name"
  "Define name for outputting encrypted regions."
  :type 'string
  :group 'encrypt-region)

(defcustom encrypt-region--decrypt-buf-name "name"
  "Define name for outputting decrypted regions."
  :type 'string
  :group 'encrypt-region)

(defun encrypt-region--pad (input length)
  "Pad string to a given length."
  ;; Thanks to auth-source.el
  ;; https://github.com/emacs-mirror/emacs/blob/master/lisp/auth-source.el
  (let ((p (- length (mod (length input) length))))
    (concat input (make-string p p))))

(defun encrypt-region--unpad (string)
  "Remove padding from string."
  (substring string 0 (- (length string)
			 (aref string (1- (length string))))))

(defun decrypt-region (start end)
  "Decrypt a base64-encoded encrypted region."
  (interactive "r")
  (let ((ctext-str (split-string
		    (buffer-substring start end) "###")))
    (with-output-to-temp-buffer
	(generate-new-buffer encrypt-region--buf-name)
      (prin1 (encrypt-region--unpad
	      (decode-coding-string
	       (gnutls-symmetric-decrypt "CHACHA20-POLY1305"
					 (copy-sequence encrypt-region--key)
	                                 ; Decode the IV
					 (base64-decode-string (cadr ctext-str))
					 ; Decode the ciphertext
					 (base64-decode-string (car ctext-str)))
	       'utf-8)))
      ; Output to the decrypt temporary buffer
      (switch-to-buffer encrypt-region--decrypt-buf-name))))
     
(defun encrypt-region (start end)
  "Encrypts a region and outputs its base64 encoding."
  (interactive "r")
  (with-output-to-temp-buffer
      (generate-new-buffer encrypt-region--buf-name)
    (princ (mapconcat
	    #'base64-encode-string
	    (gnutls-symmetric-encrypt "CHACHA20-POLY1305"
				      (copy-sequence encrypt-region--key)
				      (list 'iv-auto 12)
				      (encrypt-region--pad
				       (encode-coding-string (buffer-substring start end) 'utf-8)
				       64)
				      "") "###"))
    (switch-to-buffer encrypt-region--buf-name)))

(provide 'encrypt-region)
