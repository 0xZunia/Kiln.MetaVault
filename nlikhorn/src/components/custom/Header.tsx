import { Container, HStack, Heading } from "@chakra-ui/react";
import { ColorModeButton } from "../ui/color-mode";
import { useLocation } from "@tanstack/react-router";
import { useMemo, useState } from "react";

const pathToTitle: { [key: string]: string } = {
	"/": "Dashboard",
	"/earn": "Earn",
	"/vault": "Vault",
};

export function Header() {
	const { pathname } = useLocation();

	const title = useMemo(() => pathToTitle[pathname], [pathname]);
	useState(() => {
		document.title = `Nlik'horne | ${title}`;
	});

	return (
		<Container
			zIndex={"sticky"}
			position={"sticky"}
			top={3}
			left={0}
			padding={0}
		>
			<HStack
				justify={"space-between"}
				paddingY={2}
				paddingX={3}
				rounded={"md"}
				shadow={"sm"}
				borderWidth={"1px"}
				borderColor={"border"}
				colorPalette={"orange"}
				bgColor={"bg"}
			>
				<Heading>{title}</Heading>
				<ColorModeButton />
			</HStack>
		</Container>
	);
}
