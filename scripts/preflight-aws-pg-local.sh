#!/bin/bash
# Local Preflight check for mediaserver AWS PG deployment
set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function check_env_vars() {
	echo -e "${YELLOW}Checking required environment variables...${NC}"
	local missing=0
	for var in PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE S3_BUCKET_NAME AWS_REGION JWT_SECRET; do
		if [ -z "${!var}" ]; then
			echo -e "${RED}Missing: $var${NC}"
			missing=1
		else
			echo -e "${GREEN}OK: $var set${NC}"
		fi
	done
	return $missing
}

function check_db_connectivity() {
	echo -e "${YELLOW}Checking PostgreSQL connectivity...${NC}"
	PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c '\dt' >/dev/null 2>&1 && \
		echo -e "${GREEN}OK: Connected to PostgreSQL${NC}" || {
			echo -e "${RED}Failed: Cannot connect to PostgreSQL${NC}"
			return 1
		}
}

function check_media_table() {
	echo -e "${YELLOW}Checking for 'media' table in PostgreSQL...${NC}"
	local exists=$(PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc "SELECT to_regclass('public.media')")
	if [[ "$exists" == "media" ]]; then
		echo -e "${GREEN}OK: 'media' table exists${NC}"
	else
		echo -e "${RED}Missing: 'media' table${NC}"
		return 1
	fi
}

function check_s3_access() {
	echo -e "${YELLOW}Checking S3 bucket access...${NC}"
	aws s3 ls "s3://$S3_BUCKET_NAME" >/dev/null 2>&1 && \
		echo -e "${GREEN}OK: S3 bucket '$S3_BUCKET_NAME' accessible${NC}" || {
			echo -e "${RED}Failed: Cannot access S3 bucket '$S3_BUCKET_NAME'${NC}"
			return 1
		}
}

function check_dependencies() {
	echo -e "${YELLOW}Checking Node.js and pnpm dependencies...${NC}"
	pnpm install --frozen-lockfile && echo -e "${GREEN}OK: Dependencies installed${NC}" || {
		echo -e "${RED}Failed: Dependency installation${NC}"
		return 1
	}
}

echo -e "${YELLOW}Local Preflight Check for mediaserver AWS PG Deployment${NC}\n"
check_env_vars || exit 1
check_db_connectivity || exit 1
check_media_table || exit 1
check_s3_access || exit 1
check_dependencies || exit 1
echo -e "\n${GREEN}Preflight check complete. Ready for local build.${NC}"
