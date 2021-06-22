public class CSVColIterator implements Iterator<String> {
  private String colDelimiter = ',';
  private String textQualifier = '"';
  private String row = '';
  private Integer currentIndex = 0;

  public CSVColIterator(String row) {
    this.row = row;
  }

  public Boolean hasNext() {
    return currentIndex < row.length();
  }

  public CSVColIterator setColDelimiter(String delimiter) {
    this.colDelimiter = delimiter;
    return this;
  }

  public CSVColIterator setTextQualifier(String textQualifier) {
    this.textQualifier = textQualifier;
    return this;
  }

  public String next() {
    String token = '';
    if (row.substring(currentIndex, currentIndex + 1) == textQualifier) {
      Integer key = row.indexOf(textQualifier, currentIndex + 1);
      token = row.substring(currentIndex + 1, key);
      this.currentIndex = key + 2;
    } else {
      Integer key = row.indexOf(colDelimiter, currentIndex);
      if (key == -1) {
        key = row.length();
      }
      token = row.substring(currentIndex, key);
      this.currentIndex = key + 1;
    }
    return token;
  }
}
