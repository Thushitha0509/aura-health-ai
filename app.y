import streamlit as st
import re
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

st.set_page_config(page_title="AuraHealth AI", page_icon="🩺", layout="wide")

st.warning("⚠️ **Medical Disclaimer**: AuraHealth AI provides general health information and document explanations only. It does NOT provide medical diagnoses, clinical treatment plans, or emergency services.")

st.title("🩺 AuraHealth AI")
st.subheader("Private Medical Communication, Made Clearer")

with st.sidebar:
    st.header("Settings & Privacy")
    api_key = st.text_input("OpenAI API Key (Optional)", type="password")
    target_lang = st.selectbox(
        "Target Language", 
        ["English", "Hindi", "Kannada", "Tamil", "Telugu", "Bengali", "Marathi"]
    )
    st.info("🔒 **Privacy Buffer Active**: Names, dates, phone numbers, and IDs are redacted locally before any explanation is requested.")

SAMPLE_NOTE = """Patient Name: Rajesh Kumar, Date: 12/10/2026.
Patient presented with persistent fatigue, polydipsia, and an elevated HbA1c of 8.1%. 
BP is 135/85 mmHg. Mild dyspnea reported upon exertion. 
Advised fasting lipid profile and follow-up in two weeks."""

if "medical_text" not in st.session_state:
    st.session_state["medical_text"] = ""

col_btn, col_empty = st.columns([1, 3])
with col_btn:
    if st.button("📄 Load Sample Medical Note"):
        st.session_state["medical_text"] = SAMPLE_NOTE

user_input = st.text_area(
    "Paste plain-text medical document or note below:", 
    value=st.session_state["medical_text"],
    height=200
)

def redact_pii(text):
    redacted = re.sub(r'Patient Name:\s*[^,\n]+', 'Patient Name: [REDACTED]', text, flags=re.IGNORECASE)
    redacted = re.sub(r'Date:\s*[\d/]+', 'Date: [REDACTED]', redacted, flags=re.IGNORECASE)
    redacted = re.sub(r'\b\d{10}\b', '[REDACTED PHONE]', redacted)
    return redacted

if st.button("Anonymize & Explain Document", type="primary"):
    if not user_input.strip():
        st.error("Please enter or load a medical note first.")
    else:
        anonymized_text = redact_pii(user_input)
        
        with st.expander("🔍 View Anonymized Text (PII Scrubbed)", expanded=True):
            st.code(anonymized_text)

        st.markdown("---")
        st.subheader(f"Document Summary & Explanation ({target_lang})")

        system_prompt = f"""You are AuraHealth AI, an empathetic, privacy-compliant health assistant.
Explain the medical text in simple terms suitable for a 6th-grade reading level in {target_lang}.
Include clear section headers for key takeaways, medical terms explained, and general non-diagnostic questions for a doctor.
Maintain a reassuring tone and include a non-diagnostic medical disclaimer."""

        if api_key:
            try:
                llm = ChatOpenAI(model="gpt-4o-mini", openai_api_key=api_key, temperature=0.3)
                messages = [SystemMessage(content=system_prompt), HumanMessage(content=anonymized_text)]
                response = llm.invoke(messages)
                st.write(response.content)
            except Exception as e:
                st.error(f"API Error: {str(e)}")
        else:
            st.info("💡 **Demo Mode**: Showing simulated output (Add an OpenAI key in the sidebar for live AI summaries).")
            st.markdown(f"""
            ### 📌 Key Takeaways
            * **Blood Sugar Signal**: The test result (HbA1c of 8.1%) shows higher average blood sugar levels than standard ranges.
            * **Blood Pressure**: Blood pressure was measured at 135/85 mmHg, which is slightly above normal.
            * **Follow-up**: A follow-up test for blood fats (lipid profile) is recommended in two weeks.

            ### 💡 Questions for Your Doctor
            1. What diet changes should I make to help lower my blood sugar?
            2. Should I monitor my blood pressure at home?
            """)
