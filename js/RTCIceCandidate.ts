/**
 * RFC-5245: http://tools.ietf.org/html/rfc5245#section-15.1
 *
 * candidate-attribute   = "candidate" ":" foundation SP component-id SP
                           transport SP
                           priority SP
                           connection-address SP     ;from RFC 4566
                           port         ;port from RFC 4566
                           SP cand-type
                           [SP rel-addr]
                           [SP rel-port]
 *(SP extension-att-name SP
                                extension-att-value)
 *
 * foundation            = 1*32ice-char
 * component-id          = 1*5DIGIT
 * transport             = "UDP" / transport-extension
 * transport-extension   = token              ; from RFC 3261
 * priority              = 1*10DIGIT
 * cand-type             = "typ" SP candidate-types
 * candidate-types       = "host" / "srflx" / "prflx" / "relay" / token
 * rel-addr              = "raddr" SP connection-address
 * rel-port              = "rport" SP port
 * extension-att-name    = byte-string    ;from RFC 4566
 * extension-att-value   = byte-string
 * ice-char              = ALPHA / DIGIT / "+" / "/"
 */

/**
 * RFC-3261: https://tools.ietf.org/html/rfc3261#section-25.1
 *
 * token          =  1*(alphanum / "-" / "." / "!" / "%" / "*"
                     / "_" / "+" / "`" / "'" / "~" )
 */

/**
 * RFC-4566: https://tools.ietf.org/html/rfc4566#section-9
 *
 * port =                1*DIGIT
 * IP4-address =         b1 3("." decimal-uchar)
 * b1 =                  decimal-uchar
						 ; less than "224"
 * ; The following is consistent with RFC 2373 [30], Appendix B.
 * IP6-address =         hexpart [ ":" IP4-address ]
 * hexpart =             hexseq / hexseq "::" [ hexseq ] /
						 "::" [ hexseq ]
 * hexseq  =             hex4 *( ":" hex4)
 * hex4    =             1*4HEXDIG
 * decimal-uchar =       DIGIT
						 / POS-DIGIT DIGIT
						 / ("1" 2*(DIGIT))
						 / ("2" ("0"/"1"/"2"/"3"/"4") DIGIT)
						 / ("2" "5" ("0"/"1"/"2"/"3"/"4"/"5"))
 */

const candidateFieldName = {
		FOUNDATION: 'foundation',
		COMPONENT_ID: 'component',
		TRANSPORT: 'protocol',
		PRIORITY: 'priority',
		CONNECTION_ADDRESS: 'address',
		PORT: 'port',
		CANDIDATE_TYPE: 'type',
		REMOTE_CANDIDATE_ADDRESS: 'relatedAddress',
		REMOTE_CANDIDATE_PORT: 'relatedPort'
	},
	candidateType = {
		HOST: 'host',
		SRFLX: 'srflx',
		PRFLX: 'prflx',
		RELAY: 'relay'
	},
	transport = {
		TCP: 'TCP',
		UDP: 'UDP'
	},
	IPV4SEG = '(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])',
	IPV4ADDR = `(?:${IPV4SEG}\\.){3}${IPV4SEG}`,
	IPV6SEG = '[0-9a-fA-F]{1,4}',
	IPV6ADDR =
		`(?:${IPV6SEG}:){7,7}${IPV6SEG}|` + // 1:2:3:4:5:6:7:8
		`(?:${IPV6SEG}:){1,7}:|` + // 1::                              1:2:3:4:5:6:7::
		`(?:${IPV6SEG}:){1,6}:${IPV6SEG}|` + // 1::8             1:2:3:4:5:6::8  1:2:3:4:5:6::8
		`(?:${IPV6SEG}:){1,5}(?::${IPV6SEG}){1,2}|` + // 1::7:8           1:2:3:4:5::7:8  1:2:3:4:5::8
		`(?:${IPV6SEG}:){1,4}(?::${IPV6SEG}){1,3}|` + // 1::6:7:8         1:2:3:4::6:7:8  1:2:3:4::8
		`(?:${IPV6SEG}:){1,3}(?::${IPV6SEG}){1,4}|` + // 1::5:6:7:8       1:2:3::5:6:7:8  1:2:3::8
		`(?:${IPV6SEG}:){1,2}(?::${IPV6SEG}){1,5}|` + // 1::4:5:6:7:8     1:2::4:5:6:7:8  1:2::8
		`${IPV6SEG}:(?:(?::${IPV6SEG}){1,6})|` + // 1::3:4:5:6:7:8   1::3:4:5:6:7:8  1::8
		`:(?:(?::${IPV6SEG}){1,7}|:)|` + // ::2:3:4:5:6:7:8  ::2:3:4:5:6:7:8 ::8       ::
		`fe80:(?::${IPV6SEG}){0,4}%[0-9a-zA-Z]{1,}|` + // fe80::7:8%eth0   fe80::7:8%1     (link-local IPv6 addresses with zone index)
		`::(?:ffff(?::0{1,4}){0,1}:){0,1}${IPV4ADDR}|` + // ::255.255.255.255   ::ffff:255.255.255.255  ::ffff:0:255.255.255.255 (IPv4-mapped IPv6 addresses and IPv4-translated addresses)
		`(?:${IPV6SEG}:){1,4}:${IPV4ADDR}`, // 2001:db8:3:4::192.0.2.33  64:ff9b::192.0.2.33 (IPv4-Embedded IPv6 Address)
	TOKEN = "[0-9a-zA-Z\\-\\.!\\%\\*_\\+\\`\\'\\~]+",
	CANDIDATE_TYPE = Object.values(candidateType).join('|') + TOKEN,
	pattern = {
		COMPONENT_ID: '[0-9]{1,5}',
		FOUNDATION: '[a-zA-Z0-9\\+\\/\\-]+',
		PRIORITY: '[0-9]{1,10}',
		TRANSPORT: transport.UDP + '|' + TOKEN,
		CONNECTION_ADDRESS: IPV4ADDR + '|' + IPV6ADDR,
		PORT: '[0-9]{1,5}',
		CANDIDATE_TYPE: CANDIDATE_TYPE
	},
	ICE_CANDIDATE_PATTERN = new RegExp(
		`candidate:(${pattern.FOUNDATION})` + // 10
			`\\s(${pattern.COMPONENT_ID})` + // 1
			`\\s(${pattern.TRANSPORT})` + // UDP
			`\\s(${pattern.PRIORITY})` + // 1845494271
			`\\s(${pattern.CONNECTION_ADDRESS})` + // 13.93.107.159
			`\\s(${pattern.PORT})` + // 53705
			'\\s' +
			'typ' +
			`\\s(${pattern.CANDIDATE_TYPE})` + // typ prflx
			'(?:\\s' +
			'raddr' +
			`\\s(${pattern.CONNECTION_ADDRESS})` + // raddr 10.1.221.7
			'\\s' +
			'rport' +
			`\\s(${pattern.PORT}))?` // rport 54805
	);

function candidateToJson(iceCandidate?: string) {
	if (iceCandidate && typeof iceCandidate === 'string') {
		const iceCandidateFields = iceCandidate.match(ICE_CANDIDATE_PATTERN);
		if (iceCandidateFields) {
			return Object.values(candidateFieldName).reduce((iceCandidateJson, fieldName, i) => {
				return {
					...iceCandidateJson,
					// i+1 because match returns the entire match result
					// and the parentheses-captured matched results.
					[fieldName]: iceCandidateFields[i + 1]
				};
			}, {} as Partial<RTCIceCandidate & { address: string | null }>);
		}
	}

	return null;
}

// See https://developer.mozilla.org/en-US/docs/Web/API/RTCIceCandidate/RTCIceCandidate
export class RTCIceCandidateShim implements RTCIceCandidate {
	readonly candidate: string;
	readonly sdpMLineIndex;
	readonly sdpMid;
	readonly usernameFragment;

	readonly component: RTCIceComponent | null;
	readonly foundation: string | null;
	readonly port: number | null;
	readonly priority: number | null;
	readonly protocol: RTCIceProtocol | null;
	readonly relatedAddress: string | null;
	readonly relatedPort: number | null;
	readonly tcpType = null; // NOT IMPLEMENTED
	readonly type: RTCIceCandidateType | null;

	// non-standard fields
	readonly address: string | null;
	readonly ip: string | null;

	constructor(private candidateInitDict?: RTCIceCandidateInit) {
		this.candidate = candidateInitDict?.candidate || '';
		this.sdpMLineIndex = candidateInitDict?.sdpMLineIndex || null;
		this.sdpMid = candidateInitDict?.sdpMid || null;
		this.usernameFragment = candidateInitDict?.usernameFragment ?? null;

		// Parse candidate SDP:
		// Example: candidate:1829696681 1 udp 2122262783 2a01:cb05:8d3e:a300:e1ad:79c1:7096:8ba0 49778 typ host generation 0 ufrag c9L6 network-id 2 network-cost 10
		const iceCandidateFields = candidateToJson(this.candidate);

		this.component = iceCandidateFields?.component ?? null;
		this.foundation = iceCandidateFields?.foundation ?? null;
		this.port = iceCandidateFields?.port ?? null;
		this.priority = iceCandidateFields?.priority ?? null;
		this.protocol = iceCandidateFields?.protocol ?? null;
		this.relatedAddress = iceCandidateFields?.relatedAddress ?? null;
		this.relatedPort = iceCandidateFields?.relatedPort ?? null;
		this.type = iceCandidateFields?.type ?? null;

		this.address = iceCandidateFields?.address ?? null;
		this.ip = this.address;
	}

	toJSON(): RTCIceCandidateInit {
		return this;
	}
}
