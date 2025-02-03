import { Loader, Spinner } from "@chakra-ui/react";

export function SimpleLoader() {
	return <Loader spinner={<Spinner size="xl" color="orange" />} />;
}
