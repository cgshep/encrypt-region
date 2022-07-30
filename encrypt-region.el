;; encrypt-region.el -- Encrypts and decrypts regions
;;
;; Copyright (c) 2022, Carlton Shepherd
;; Author: Carlton Shepherd <carlton@linux.com> (https://cs.gl)
;; Version: 0.1
;; Created: 14 October 2021
;; Modified: 30 July 2022
;; Keywords: encryption, cryptography
;; License: GPLv3
;; URL: https://github.com/cgshep/encrypt-region
;;
;; Notes: Authenticated encryption is provided by GnuTLS' ChaCha20-Poly1305
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

(defvar encrypt-region--encrypt-buf-name "*Encrypt Region*")
(defvar encrypt-region--decrypt-buf-name "*Decrypt Region*")

(defun encrypt-region--pad (input length)
  "Pad string to a given length using PKCS#7."
  ;; Thanks to auth-source.el
  ;; https://github.com/emacs-mirror/emacs/blob/master/lisp/auth-source.el
  (let ((p (- length (mod (length input) length))))
    (concat input (make-string p p))))

(defun encrypt-region--unpad (string)
  "Remove padding from string."
  (substring string 0 (- (length string)
			 (aref string (1- (length string))))))
     
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
    (switch-to-buffer encrypt-region--encrypt-buf-name)))

(defun decrypt-region (start end)
  "Decrypt a base64-encoded encrypted region."
  (interactive "r")
  (let ((ctext-str (split-string
		    (buffer-substring start end) "###")))
    (with-output-to-temp-buffer
	(generate-new-buffer encrypt-region--decrypt-buf-name)
      (prin1 (encrypt-region--unpad
	      (decode-coding-string
	       (gnutls-symmetric-decrypt "CHACHA20-POLY1305"
					 (copy-sequence encrypt-region--key)
	                                 ; Decode the IV
					 (base64-decode-string (cadr ctext-str))
					 ; Decode the ciphertext
					 (base64-decode-string (car ctext-str))))
	       'utf-8))
      ; Output to the decrypt temporary buffer
      (switch-to-buffer encrypt-region--decrypt-buf-name))))

(provide 'encrypt-region)
;; encrypt-region.el ends here
