import TextInput from "ink-text-input";
import { Box, Text } from "ink";

type SearchInputProps = {
  query: string;
  setQuery: (value: string) => void;
  placeholder?: string;
};

export const SearchInput = ({
  query,
  setQuery,
  placeholder = "Search...",
}: SearchInputProps) => (
  <Box>
    <Text>🔍 </Text>
    <TextInput value={query} onChange={setQuery} placeholder={placeholder} />
  </Box>
);
