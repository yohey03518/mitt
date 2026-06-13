import Testing
@testable import mac_ocr_capture

@Suite struct LanguageParserTests {
    @Test func testParseLanguagesWithFlag() {
        let args = ["/path/to/binary", "--lang", "zh-Hans,ja-JP,en-US"]
        let result = LanguageParser.parseLanguages(from: args)
        #expect(result == ["zh-Hans", "ja-JP", "en-US"])
    }
    
    @Test func testParseLanguagesWithShortFlag() {
        let args = ["/path/to/binary", "-l", "en-US"]
        let result = LanguageParser.parseLanguages(from: args)
        #expect(result == ["en-US"])
    }
    
    @Test func testParseLanguagesNoFlag() {
        let args = ["/path/to/binary"]
        let result = LanguageParser.parseLanguages(from: args)
        #expect(result.isEmpty)
    }
    
    @Test func testParseLanguagesEmptyValue() {
        let args = ["/path/to/binary", "--lang", ""]
        let result = LanguageParser.parseLanguages(from: args)
        #expect(result.isEmpty)
    }
    
    @Test func testParseLanguagesMissingValue() {
        let args = ["/path/to/binary", "--lang"]
        let result = LanguageParser.parseLanguages(from: args)
        #expect(result.isEmpty)
    }
}
