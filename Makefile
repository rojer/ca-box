# These are external parameters.
export CN
export ALTN1
export ALTN2
export ALTN3

DAYS ?= 365
CLIENT ?= 0
CA_DATA_DIR ?= ./data

.PHONY: ca check-ca-data clean clean-ca

export CA_DATA_DIR
ifeq "$(CLIENT)" "1"
export EKU=clientAuth
else
export EKU=serverAuth
endif

$(CA_DATA_DIR)/ca.crt: cnf/ca.cnf
	openssl req \
		-out $@ \
		-keyout $(@:.crt=.key) \
		-newkey ec:cnf/prime256v1.params \
		-sha256 \
		-nodes \
		-days 3653 \
		-x509 \
		-config $< \
		-subj "$(CA_DN)" \
		-text

check-ca-data:
	@[ ! -e $(CA_DATA_DIR) ] || { printf '\n *** CA data already exists! Use "make clean-ca" to wipe. ***\n\n'; exit 1; }

$(CA_DATA_DIR):
	mkdir $@

ca: check-ca-data $(CA_DATA_DIR) $(CA_DATA_DIR)/ca.crt
	mkdir $(CA_DATA_DIR)/certs
	echo -n true > $(CA_DATA_DIR)/index.txt
	touch $(CA_DATA_DIR)/index.txt.attr
	cat $(CA_DATA_DIR)/ca.crt

%.csr:
ifeq "$(CN)" ""
	$(eval CN=$(@:%.csr=%))
endif
	openssl req \
		-out $@ \
		-keyout $(@:.csr=.key) \
		-newkey ec:cnf/prime256v1.params \
		-nodes \
		-text \
		-config cnf/cert0$(ALTN1:%=1)$(ALTN2:%=2)$(ALTN3:%=3).cnf

%.crt.tmp: %.csr
	rm -f $(CA_DATA_DIR)/ca.srl
	openssl ca \
		-in $< \
		-out $@ \
		-config cnf/ca.cnf \
		-days $(DAYS) \
		-create_serial \
		-batch

%.crt: %.crt.tmp
	openssl x509 \
		-in $< \
		-text > $@
	cat $@

clean:
	rm -f *.crt *.key

clean-ca: clean
	rm -rf $(CA_DATA_DIR)
