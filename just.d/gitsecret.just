# Encrypt the files
encrypt:
	git secret hide -m

# Decrypt the files
decrypt:
	git secret reveal -f
