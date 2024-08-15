# These are external parameters.
export CN
export ALTN1
export ALTN2
export ALTN3

# Generate ECDSA P-256 keys by default.
KT ?= ec:cnf/prime256v1.params

CN ?=
DN ?=

CA ?= 0
# Explicit validity, format: 20240801010000Z (date -u +%Y%m%d%H%M%SZ)
START_DATE ?=
END_DATE ?=

ifndef CLIENT
# Default is to generate a server cert
CLIENT = 0
SERVER = 1
else ifeq "$(CLIENT)" "1"
# If only CLIENT is specified, default SERVER to 0
SERVER ?= 0
endif

ROOT_KT ?= ec:cnf/secp384r1.params
CA_DATA_DIR ?= ./data

export SIGN_CERT ?= $(CA_DATA_DIR)/ca.crt
export SIGN_KEY ?= $(SIGN_CERT:.crt=.key)

export CA_DATA_DIR

ifeq "$(CLIENT)$(SERVER)" "00"
$(error Both CLIENT and SERVER cannot be 0)
else ifeq "$(CLIENT)$(SERVER)" "01"
export _EKU=serverAuth
else ifeq "$(CLIENT)$(SERVER)" "10"
export _EKU=clientAuth
else ifeq "$(CLIENT)$(SERVER)" "11"
export _EKU=clientAuth,serverAuth
else
$(error CLIENT and SERVER must be 0 or 1)
endif

ifeq "$(DN)" ""
DN = /CN=$(CN)
endif

ifneq "$(START_DATE)$(END_DATE)" ""
ifneq "$(START_DATE)" ""
_VALIDITY = -startdate $(START_DATE)
else
_VALIDITY = -startdate $(shell date -u +%Y%m%d%H%M%SZ)
endif
_VALIDITY += -enddate $(END_DATE)
else ifdef DAYS
_VALIDITY = -days $(DAYS)
else ifeq "$(CA)" "1"
_VALIDITY = -days 3653
else
_VALIDITY = -days 365
endif

ifeq "$(CA)" "1"
export _CNF=cnf/ca.cnf
export _CA = TRUE
else ifneq "$(ALTN1:%=1)$(ALTN2:%=2)$(ALTN3:%=3)" ""
export _CNF=cnf/cert_altn.cnf
export _CA = FALSE
export _ALTN_SECTION=$(ALTN1:%=1)$(ALTN2:%=2)$(ALTN3:%=3)
else
export _CNF=cnf/cert.cnf
export _CA = FALSE
endif

.PHONY: ca check-ca-data clean clean-ca

$(CA_DATA_DIR)/ca.crt: cnf/ca.cnf
	_CA=TRUE openssl req \
		-subj "$(DN)" \
		-out $(@:.crt=.csr) \
		-keyout $(@:.crt=.key) \
		-newkey $(ROOT_KT) \
		-nodes \
		-config $<
	mkdir $(CA_DATA_DIR)/certs
	echo -n true > $(CA_DATA_DIR)/index.txt
	touch $(CA_DATA_DIR)/index.txt.attr
	_CA=TRUE openssl ca \
		-in $(@:.crt=.csr) \
		-keyfile $(@:.crt=.key) \
		-out $@ \
		-config cnf/ca.cnf \
		-create_serial \
		-batch \
		-selfsign \
		-preserveDN \
		$(_VALIDITY)
	rm $(@:.crt=.csr)

check-ca-data:
	@[ "$(CN)$(DN)" != "/CN=" ] || { printf '\n *** Root CN or DN must be specified ***\n\n'; exit 1; }
	@[ ! -e "$(CA_DATA_DIR)" ] || { printf '\n *** CA data already exists! Use "make clean-ca" to wipe. ***\n\n'; exit 1; }

$(CA_DATA_DIR):
	mkdir $@

ca: check-ca-data $(CA_DATA_DIR) $(CA_DATA_DIR)/ca.crt
	cat $(CA_DATA_DIR)/ca.crt

%.csr:
ifeq "$(CN)$(DN)" "/CN="
	$(eval DN=/CN=$(@:%.csr=%))
endif
	openssl req \
		-subj "$(DN)" \
		-out $@ \
		-keyout $(@:.csr=.key) \
		-newkey $(KT) \
		-nodes \
		-text \
		-config $(_CNF)

%.crt.tmp: %.csr
	rm -f $(CA_DATA_DIR)/ca.srl
	openssl ca \
		-in $< \
		-out $@ \
		-config cnf/ca.cnf \
		$(_VALIDITY) \
		-preserveDN \
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
